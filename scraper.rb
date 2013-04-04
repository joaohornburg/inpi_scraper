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
    search_for "UFSC"
  end
  
  private
  
  def init_logger
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
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
    search_form = @search_page.form_with(:name => "F_PatenteBasico")
    @log.debug search_form
    search_form.field_with(:name => "ExpressaoPesquisa").value = name
    search_form.field_with(:name => "Coluna").options[2].select
    @log.debug search_form.field_with(:name => "Coluna")
    search_button = search_form.button_with(:name => "Botao")
    @results_page = @agent.submit search_form, search_button
    @log.debug "Resultados para #{name}: \n#{@results_page.body}"
  end
    
end

scrapper = InpiScrapper.new
scrapper.scrap