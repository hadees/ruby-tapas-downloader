require 'nokogiri'

# An Ruby Tapas Episode.
class RubyTapasDownloader::Downloadables::Episode <
                                              RubyTapasDownloader::Downloadable

  # @return [String] the title of the Episode.
  attr_reader :title

  # @return [String] the link to the Episode.
  attr_reader :link

  # @return [Set<RubyTapasDownloader::Downloadables::File>] the Set of Files
  #   for that episode.
  attr_reader :files

  attr_reader :date

  def initialize(title, link, files, date)
    @title = title
    @link  = link
    @files = files
    @date  = date
  end

  # Clean title to be used in path names.
  #
  # @return [String] the sanitized title.
  def sanitized_title
    @sanitized_title ||= title.downcase.gsub(/[\s\x00\/\\:\*\?\"<>\|]+/, '-')
  end

  # Download the Episode.
  #
  # @param (see: RubyTapasDownloader::Downloadables::Catalog#download)
  def download(basepath, agent)
    episode_path = File.join basepath, sanitized_title
    if already_downloaded? episode_path
      RubyTapasDownloader.logger.debug 'Skipping downloaded episode ' \
        "`#{ title }' in `#{ episode_path }'..."
    else
      RubyTapasDownloader.logger.info 'Starting download of episode ' \
        "`#{ title }' in `#{ episode_path }'..."
      FileUtils.mkdir_p episode_path
      files.each { |file| file.download episode_path, agent }
      create_kodi_nfo!(episode_path)
    end
  end

  def already_downloaded?(basepath)
    files.all? { |file| File.exist? File.join(basepath, file.name) }
  end

  def ==(other)
    title == other.title && link == other.link && files == other.files
  end

  def eql?(other)
    title.eql?(other.title) && link.eql?(other.link) && files.eql?(other.files)
  end

  def hash
    title.hash + link.hash + files.hash
  end

  def create_kodi_nfo!(episode_path)
    nfo_xml = Nokogiri::XML::Builder.new do |xml|
      xml.send(:episodedetails) {
        xml.send(:title, title)
        xml.send(:season, date.year)
        xml.send(:episode, episode_number)
        xml.send(:aired, date.to_s)
        xml.send(:credits, 'Avdi Grimm')
      }
    end
    File.open(File.join(episode_path, nfo_file_name), 'w') { |file| file.write(nfo_xml.to_xml) }
  end

  def movie_file
    files.find { |f| File.extname(f.name) == ".mp4" }
  end

  def episode_number
    movie_file.name.to_i
  end

  def nfo_file_name
    movie_file.name.sub '.mp4', '.nfo'
  end

end
