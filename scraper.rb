# coding: utf-8

require 'mechanize'

class Mechanize
  def print_cookies
    self.cookie_jar.each do |cookie|
      p cookie.to_s
    end
  end
end

class InpiScrapper
  
  def initialize
    init_urls
    init_folders
    init_agent
  end

  def scrap
    main_page = bypass_captcha
    p main_page.body
  end
  
  private
  
  def init_urls
    @url = "http://formulario.inpi.gov.br/MarcaPatente/jsp/servimg/validamagic.jsp?BasePesquisa=Patentes"
    @captcha_url = "http://formulario.inpi.gov.br/MarcaPatente/servlet/ServImg"
    @captcha_file_name = "images/captcha.jpg"
  end
  
  def init_folders
    FileUtils.mkdir_p 'images'
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
  
  def bypass_captcha
    p "acessando o site ..."
    captcha_page = @agent.get(@url)
    @agent.print_cookies
  
    p "baixando o captcha..."
    captcha = @agent.get(@captcha_url)
    @agent.print_cookies
  
    p "o captcha será aberto em uma janela do seu navegador padrão. Volte para o terminal e digite o valor dele. <ENTER> para continuar"
    captcha.save @captcha_file_name
    spawn("open captcha.html")
    captcha_txt = gets.split("\n").first.upcase
    p "o captcha digitado é: #{captcha_txt}"
  
    p "preenchendo o captcha no site do IPNI ..."
    captcha_form = captcha_page.form_with :name => "input"
    p captcha_form
    captcha_form.field_with(:name => "TextoFigura").value = captcha_txt
    p captcha_form.field_with(:name => "TextoFigura")
  
    @agent.print_cookies
  
    p "clicando no botão enviar..."
    captcha_button = captcha_form.button_with(:value => "acessar")
    p captcha_button
    search_page = @agent.submit captcha_form, captcha_button
    @agent.print_cookies
    search_page
  end
    
end

scrapper = InpiScrapper.new
scrapper.scrap