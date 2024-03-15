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
    # @langchain = Langchain::Vectorsearch::Pgvector.new(url: @database_url, index_name: 'employee_profile_embeddings', llm: @llm)
    @langchain = Langchain::Vectorsearch::Pgvector.new(url: @database_url, index_name: 'employee_profile_embeddings_test', llm: @llm)
  end

  def initialize_vector_database
    puts "Initializing..."
    @langchain.create_default_schema # Creates the PGVector extension for the database and initializes the employee_profile_embeddings table
    puts "Done!"
  end

  def seed_vector_database
    puts "Creating records..."
    employee_profiles = build_employee_profiles_array # Fetches employee profiles from the profiles folder and chunks them into smaller pieces
    # employee_profile_paths = build_employee_profile_path_array
    puts "Generating embeddings..."
    @langchain.add_texts(texts: employee_profiles) # Generates embeddings for each employee profile and stores them in the database
    # TODO: add source, add employee name metadata, see if it can read multi column pdf
    # @langchain.add_data(paths: employee_profile_paths, options: { source: '' })
    puts "Done!"
  end

  def close_connection
    @langchain.db.disconnect
  end

  private

  # def build_employee_profile_path_array 
  #   # my_pdf = Langchain.root.join("path/to/my.pdf")
  #   # [my_pdf, my_text, my_docx]
  #   profiles_dir = Rails.root.join('lib', 'test_profiles', '*.pdf') # Ensure this path is correct
  #   Dir[profiles_dir].map do |pdf_path|
  #     Langchain.root.join(pdf_path)
  #   end
  # end

  def build_employee_profiles_array
    profiles = fetch_employee_profiles_from_folder
    profiles.map do |profile|
      chunks = Langchain::Chunker::Text.new(profile[:content], chunk_size: 2500, chunk_overlap: 500, separator: "\n").chunks
      chunks.map { |chunk| "#{profile[:name]} - \n #{chunk.text}" }
    end.flatten # Ensure you have a flat array of strings if required by @langchain.add_texts
  end

  def fetch_employee_profiles_from_folder
    # go into the lib/profiles directory and loop through every pdf 
    profiles_dir = Rails.root.join('lib', 'test_profiles', '*.pdf') # Ensure this path is correct
    Dir[profiles_dir].map do |pdf_path|
      extract_text_from_pdf(pdf_path)
    end
  end

  def extract_text_from_pdf(path)
    reader = PDF::Reader.new(path)
    text = reader.pages.map(&:text).join(" ")
    {name: text.lines.first.strip, content: text}
  end
end
