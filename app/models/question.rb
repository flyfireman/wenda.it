class Question
  include MongoMapper::Document

  key :title,           String
  key :content,         String
  key :votes_count,     Integer, :default => 0
  key :answers_count,   Integer, :default => 0
  key :views_count,     Integer, :default => 0
  key :user_id,         ObjectId
  key :best_answer_id,  ObjectId
  key :tags,          Array
  # tags in ruby: [{"id" => "4d1033f698d1b102cb00000a", "name" => "ruby"}, {"id" => "4d1033f698d1b102cb00000b", "name" =>"rails"}]
  # tags in bson: [{"id" : "4d1033f698d1b102cb00000a", "name" : "ruby"}, {"id" => "4d1033f698d1b102cb00000b", "name" : "rails"}]
  timestamps!
  
  belongs_to :user
  many :answers
  
  def self.hot(limit = LIMIT)
    all(:limit => limit, :order => "votes_count DESC, answers_count DESC, views_count DESC, created_at DESC")
  end
  
  def self.paginate(page = 1, limit = LIMIT)
    raise "Wrong page" if page.to_i < 1
    all(:limit => limit, :offset => (page.to_i-1)*limit, :order => "created_at DESC")
  end
  
  def self.unanswered(page = 1, limit = LIMIT)
    raise "Wrong page" if page.to_i < 1
    all(:best_answer_id => nil, :limit => limit, :offset => (page.to_i-1)*limit, :order => "created_at DESC")
  end
  
  def self.tagged(tag, page = 1, limit = LIMIT)
    raise "Wrong page" if page.to_i < 1
    all("tags.name" => tag, :limit => limit, :offset => (page.to_i-1)*limit, :order => "created_at DESC")
  end
  
  def save_tags(tags)
    tags_array = []
    tags.split(" ").uniq.each do |tag|
      t = Tag.find_by_name(tag)
      if t
        t.questions_count += 1 if !self.has_tag(t)
      else
        t = Tag.new
        t.name = tag
      end
      t.save
      tags_array << t
    end
    self.tags = tags_array.map{|t|{"id" => t.id.to_s, "name" => t.name}}
  end
  
  def has_tag(t)
    self.tags.each do |tag|
      return true if tag["name"] == t.name
    end
    return false
  end
  
  def has_best_answer?
    !self.best_answer_id.nil?
  end
  
  def best_answer
    Answer.find(best_answer_id)
  end
end
