class AddSpeechLanguageToSubmissions < ActiveRecord::Migration
  def change
    add_column  :submissions, :speech_language, :string
  end
end
