# coding: utf-8

require 'mechanize'

class Mechanize
  def print_cookies
    self.cookie_jar.each do |cookie|
      p cookie.to_s
    end
  end
end

def scrap
  
  url = "http://formulario.inpi.gov.br/MarcaPatente/jsp/servimg/validamagic.jsp?BasePesquisa=Patentes"
  search_url = "http://formulario.inpi.gov.br/MarcaPatente/jsp/patentes/patenteSearchBasico.jsp"
  captcha_url = "http://formulario.inpi.gov.br/MarcaPatente/servlet/ServImg"
  captcha_file_name = "images/captcha.jpg"
  
  FileUtils.mkdir_p 'images'
  begin
    FileUtils.rm 'images/captcha.jpg'
  rescue Exception => e
    # NADA
  end
  
  agent = Mechanize.new
  
  p "lets see whats there..."
  page = agent.get(url)
  agent.print_cookies
  
  p "first we need get the captcha..."
  captcha = agent.get(captcha_url)
  agent.print_cookies
  
  captcha.save captcha_file_name
  spawn("open captcha.html")
  puts "Type captcha. <ENTER> to continue"
  captcha_txt = gets.split("\n").first.upcase
  p captcha_txt
  
  p "now the serious business..."
  # TODO fill form
end

def save_capcha
  # TODO delete if cookies works
  captcha_page = agent.get(url)
  agent.get("#{url}/MarcaPatente/servlet/ServImg").save_as captcha_file_name
  system("open #{captcha_file_name}")
end

def load_cookies
  unless agent.cookie_jar.load('cookies.txt', :cookiestxt)
    puts "COULD NOT LOAD COOKIES!!!"
  end
end

scrap