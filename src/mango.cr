require "./server"
require "./context"
require "./mangadex/*"
require "option_parser"

VERSION = "0.3.0"

config_path = nil

OptionParser.parse do |parser|
  parser.banner = "Mango e-manga server/reader. Version #{VERSION}\n"

  parser.on "-v", "--version", "Show version" do
    puts "Version #{VERSION}"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.on "-c PATH", "--config=PATH",
    "Path to the config file. Default is `~/.config/mango/config.yml`" do |path|
    config_path = path
  end
end

config = Config.load config_path
logger = Logger.new config.log_level
storage = Storage.new config.db_path, logger
library = Library.new config.library_path, config.scan_interval, logger, storage
queue = MangaDex::Queue.new config.mangadex["download_queue_db_path"].to_s,
  logger
api = MangaDex::API.new config.mangadex["api_url"].to_s
MangaDex::Downloader.new queue, api, config.library_path,
  config.mangadex["download_wait_seconds"].to_i,
  config.mangadex["download_retries"].to_i, logger

context = Context.new config, logger, library, storage, queue

server = Server.new context
server.start
