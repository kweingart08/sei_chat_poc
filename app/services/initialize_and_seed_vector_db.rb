class InitializeAndSeedVectorDb

  def initialize
    @llm = Langchain::LLM::OpenAI.new(api_key: ENV['OPENAI_KEY'])
    @database_url = ENV['DATABASE_URL'] || Rails.configuration.database_configuration[Rails.env]
  end

  def run
    instantiate_langchainrb
    initialize_vector_database
    seed_vector_database
    close_connection
  end

  def instantiate_langchainrb
    @langchain = Langchain::Vectorsearch::Pgvector.new(url: @database_url, index_name: 'employee_profile_embeddings', llm: @llm)
  end

  def initialize_vector_database
    puts "Initializing..."
    @langchain.create_default_schema # Creates the PGVector extension for the database and initializes the employee_profile_embeddings table
    puts "Done!"
  end

  def seed_vector_database
    puts "Creating records..."
    employee_profiles = build_employee_profiles_array # Fetches employee profiles from the profiles folder and chunks them into smaller pieces
    puts "Generating embeddings..."
    @langchain.add_texts(texts: employee_profiles) # Generates embeddings for each employee profile and stores them in the database
    puts "Done!"
  end

  def close_connection
    @langchain.db.disconnect
  end

  private

  def build_employee_profiles_array
    employee_profiles = []
    page = 1

    # loop through all pages of employee profiles from the profiles folder
    loop do
      puts "Fetching employee profiles from page #{page}..."
      profiles, total_pages = fetch_employee_profiles_from_folder(page)
      employee_profiles.concat(profiles)

      break if page >= total_pages # End loop on final page
      page += 1
    end

    # parsed_employee_profiles = employee_profiles.map do |profile|
    #   html = profile.dig("content", "rendered")
    #   title = profile.dig("title", "rendered")
    #   text = Nokogiri::HTML(html).text # parse content from HTML into text
    #   chunks = Langchain::Chunker::Text.new(text, chunk_size: 2500, chunk_overlap: 500, separator: "\n").chunks # chunk text into smaller pieces to reduce context window and produce better embeddings
    #   chunks.map { |chunk| "#{title} - \n #{chunk.text}" } # Include title with each chunk for better context
    # end

    # parsed_employee_profiles.flatten
  end

  def fetch_employee_profiles_from_folder(page)
    # url = "https://launchpadlab.com/wp-json/wp/v2/posts?per_page=15"
    # response = HTTParty.get("#{url}&page=#{page}")
    # posts = response.parsed_response

    # Retrieve total pages from the response header
    # total_pages = response.headers["x-wp-totalpages"].to_i
    # [posts, total_pages]
  end

  def chunk_text(text)
    text.scan(/.{1,#{chunk_size}}/)
  end
end
