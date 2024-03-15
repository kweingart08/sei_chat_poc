class AddUserToChatThreads < ActiveRecord::Migration[7.1]
  def change
    add_reference :chat_threads, :user, null: false, foreign_key: true
  end
end
