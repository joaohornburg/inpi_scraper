# coding: utf-8

require 'mechanize'
require 'logger'

class Mechanize
  def print_cookies logger
    self.cookie_jar.each do |cookie|
      logger.debug cookie.to_s
    end
  end
end

class InpiScrapper
  
  def initialize
    init_logger
    init_urls
    init_folders
    init_agent
    init_institutions
  end

  def scrap
    bypass_captcha
    # @institutions.each do |institution|
      # search_for institution
      search_for @institutions.first
      get_patents
    # end
  end
  
  private
  
  def init_logger
    @log = Logger.new(STDOUT)
    # @log.level = Logger::DEBUG
    @log.level = Logger::INFO
  end
  
  def init_urls
    @url = "http://formulario.inpi.gov.br/MarcaPatente/jsp/servimg/validamagic.jsp?BasePesquisa=Patentes"
    @captcha_url = "http://formulario.inpi.gov.br/MarcaPatente/servlet/ServImg"
    @captcha_file_name = "images/captcha.jpg"
    @institutions_file_name = "instituicoes.txt"
  end
  
  def init_folders
    FileUtils.mkdir_p 'images'
    clear_catpcha_image
  end
  
  def clear_catpcha_image
    begin
      FileUtils.rm 'images/captcha.jpg'
    rescue Exception => e
      # NADA
    end
  end
  
  def init_agent
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
  end
  
  def init_institutions
    @institutions = []
    File.read(@institutions_file_name).each_line do |line|
      @institutions << line.chop
    end
    @log.info("Vai pesquisar pelas instituições #{@institutions}")
  end
  
  def bypass_captcha
    attempt = 1
    begin
      clear_catpcha_image
      @log.warn "== Tentativa #{attempt} =="
      page = get_captcha_page_and_fill
      attempt = attempt + 1
    end until is_search_page( page )
    @search_page = page
    @log.debug @search_page
  end
  
  def get_captcha_page_and_fill
    @log.info "acessando o site ..."
    captcha_page = @agent.get(@url)
    @agent.print_cookies(@log)
  
    @log.warn "baixando o captcha..."
    captcha = @agent.get(@captcha_url)
    @agent.print_cookies(@log)
  
    @log.warn "o captcha será aberto em uma janela do seu navegador padrão. Volte para o terminal e digite o valor dele. <ENTER> para continuar"
    captcha.save @captcha_file_name
    spawn("open captcha.html")
    captcha_txt = gets.split("\n").first.upcase
    @log.warn "o captcha digitado é: #{captcha_txt}"
  
    @log.info "preenchendo o captcha no site do IPNI ..."
    captcha_form = captcha_page.form_with :name => "input"
    @log.debug captcha_form
    captcha_form.field_with(:name => "TextoFigura").value = captcha_txt
    @log.debug captcha_form.field_with(:name => "TextoFigura")
  
    @agent.print_cookies(@log)
  
    @log.info "clicando no botão enviar..."
    captcha_button = captcha_form.button_with(:value => "acessar")
    @log.debug captcha_button
    search_page = @agent.submit captcha_form, captcha_button
    @agent.print_cookies(@log)
    search_page
  end
  
  def is_search_page(page)
    is_search = !page.nil? && !page.form_with(:name => "F_PatenteBasico").nil?
    @log.info "conseguiu passar? #{is_search}"
    @log.error "não foi possível passar pelo CAPTCHA" unless is_search
    is_search
  end
  
  def search_for(name)
    @log.info("-> Buscando por #{name}")
    search_form = @search_page.form_with(:name => "F_PatenteBasico")
    @log.debug search_form
    search_form.field_with(:name => "ExpressaoPesquisa").value = name
    search_form.field_with(:name => "Coluna").options[2].select
    @log.debug search_form.field_with(:name => "Coluna")
    search_button = search_form.button_with(:name => "Botao")
    @results_page = @agent.submit search_form, search_button
    @results_page.encoding = 'utf-8'
  end
  
  def get_patents
    patent_links = get_patent_links
    @log.debug "#{patent_links.size} são patentes"
    patent_links.each do |pl|
      @log.info "processando #{pl.href}"
      patent_page = @agent.get pl.uri
      get_patent_data_from patent_page
      # TODO go back to list
    end
  end
  
  def get_patent_links
    links = @results_page.links
    @log.debug "achados #{links.size} links na pagina"
    patent_links = []
    links.each do |link|
      patent_links << link if link.href.start_with? "/MarcaPatente/servlet/"
    end
    patent_links
  end
  
  def get_patent_data_from patent_page
    p "================================"
    patent_page.encoding = 'utf-8'
    parser = patent_page.parser
    num_pedido = clean_str parser.xpath("/html/body/table[2]/tr[4]/td[2]/font/text()").to_s
    p "num_pedido: |#{num_pedido}|"
    p "   "
    data_deposito = clean_str parser.xpath("/html/body/table[2]/tr[5]/td[2]/font/text()").to_s
    p "data_deposito: |#{data_deposito}|"
    p "   "
    classificacao = clean_str parser.xpath("/html/body/table[2]/tr[6]/td[2]/font/a/text()").to_s
    p "classificacao: |#{classificacao}|"
    p "   "
    titulo = parser.xpath("/html/body/table[2]/tr[7]/td[2]/font/text()").to_s
    p "titulo: |#{titulo}|"
    p "   "
    resumo = parser.xpath("/html/body/table[2]/tr[8]/td[2]/font/text()").to_s
    p "resumo: |#{resumo}|"
    p "   "
    depositante = parser.xpath("/html/body/table[2]/tr[9]/td[2]/font/text()").to_s
    p "depositante: |#{depositante}|"
    p "   "
    inventores = parser.xpath("/html/body/table[2]/tr[10]/td[2]/font/text()").to_s
    p "inventores: |#{inventores}|"
    p "   "
    procurador = parser.xpath("/html/body/table[2]/tr[11]/td[2]/font/text()").to_s
    p "procurador: |#{procurador}|"
    p "   "
    link_documento = parser.xpath("/html/body/table[2]/tr[4]/td[3]/a/@href").to_s
    p "link_documento: |#{link_documento}|"
    p "   "
  end
  
  def clean_str text
    text.gsub("\n", "").gsub("\r", "").strip
  end
    
end

scrapper = InpiScrapper.new
scrapper.scrap