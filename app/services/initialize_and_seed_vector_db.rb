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
    profiles = fetch_employee_profiles_from_folder
    profiles.map do |profile|
      chunks = chunk_text(profile[:content])
      chunks.map { |chunk| "#{profile[:name]}: #{chunk}" } # Prepending the name to each chunk
    end.flatten # Ensure you have a flat array of strings if required by @langchain.add_texts


    # loop through all pages of employee profiles from the profiles folder
    # fetch_employee_profiles_from_folder(page)

    # parse the data and chunk the text using Langchain::Chunker::Text. Include the first line which is the name of the employee with each chunk for better context. 
  end

  def fetch_employee_profiles_from_folder
    # go into the lib/profiles directory and loop through every pdf 
    profiles_dir = Rails.root.join('lib', 'profiles', '*.pdf') # Ensure this path is correct
    Dir[profiles_dir].map do |pdf_path|
      extract_text_from_pdf(pdf_path)
    end
  end

  # def chunk_text(text)
  #   text.scan(/.{1,#{chunk_size}}/)
  # end

  # Assuming Langchain recommends chunks of 500 characters
  def chunk_text(text, chunk_size = 500)
    # Break the text into chunks without cutting off words
    text.scan(/\S.{0,#{chunk_size-1}}\S(?=\s|$)|\S+/)
  end


  def extract_text_from_pdf(path)
    reader = PDF::Reader.new(path)
    text = reader.pages.map(&:text).join(" ")
    {name: text.lines.first.strip, content: text}
  end
end
