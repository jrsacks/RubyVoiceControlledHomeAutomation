require 'eventmachine'
require 'sinatra'
require 'thin'
require 'socket'
require 'json'

TIVO_IP = "192.168.1.7"
TIVO_PORT = 31339
TV_IP = "192.168.1.3"
TV_PORT = 10002

class Tivo < EventMachine::Connection
  def receive_data(data)
    puts "Tivo: #{data}"
  end

  def unbind
    puts "Tivo: Disconnected"
    reconnect TIVO_IP, TIVO_PORT
  end
end

class SharpAquos < EventMachine::Connection
  def post_init
    @volume = nil
    @timer = EM::PeriodicTimer.new(1) do
      send_data "VOLM?   \r" if @volume.nil?
    end
  end

  def receive_data(data)
    puts "SharpAquos: #{data}"
    unless data.match(/ERR/) or data.match(/OK/)
      @volume = data.to_i 
    end
  end
  
  def send_command(command, val)
    if command.length == 4
      val += " " while val.length < 4
      send_data "#{command}#{val}\r"
    end
  end

  def change_volume(delta)
    @volume += delta
    send_command("VOLM", @volume.to_s)
  end

  def set_volume(volume)
    @volume = volume
    change_volume(0)
  end

  def unbind
    puts "TV: Disconnected"
    reconnect TV_IP, TV_PORT
  end
end

EventMachine.run do
  class TvRemoteWeb < Sinatra::Base
    set :bind, '0.0.0.0'
    set :tv, EventMachine.connect(TV_IP, TV_PORT, SharpAquos)
    set :tivo, EventMachine.connect(TIVO_IP, TIVO_PORT, Tivo)

    get '/tv/volume/up' do
      settings.tv.change_volume 1
    end
    get '/tv/volume/down' do
      settings.tv.change_volume -1
    end
    get '/tv/volume/:vol' do |vol|
      settings.tv.set_volume vol.to_i
    end
    get '/tv/mute' do
      settings.tv.send_command("MUTE","1")
    end
    get '/tv/unmute' do
      settings.tv.send_command("MUTE","2")
    end
    get '/tv/power/off' do 
      settings.tv.send_command("POWR", "0")
    end

    get '/tivo/ch/:chan' do |chan|
      settings.tv.send_command("POWR", "1")
      settings.tv.send_command("IAVD", "1")
      settings.tivo.send_data "FORCECH #{chan}\r"
      chan
    end

    get '/tivo/:command/:val' do |command, val|
      settings.tivo.send_data "#{command} #{val}\r"
      val
    end
  end

  TvRemoteWeb.run!
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
end
