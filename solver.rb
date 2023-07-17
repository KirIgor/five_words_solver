WORDS = File.read("dict.txt").split("\n")
FIRST_WORD = "океан" # find_best({})

class Hash
  def deep_dup
    hash = dup
    each_pair do |key, value|
      if key.frozen? && ::String === key
        hash[key] = value.deep_dup
      else
        hash.delete(key)
        hash[key.deep_dup] = value.deep_dup
      end
    end
    hash
  end
end

class LetterProps
  attr_reader :letter
  attr_accessor :positions, :excluded_positions, :included, :excluded
  alias included? included
  alias excluded? excluded

  def deep_dup
    LetterProps.new(
      letter, positions: positions.dup, excluded_positions: excluded_positions.dup, included:, excluded:
    )
  end

  def initialize(letter, positions: [], excluded_positions: [], included: false, excluded: false)
    @letter = letter
    self.positions = positions
    self.excluded_positions = excluded_positions
    self.included = included
    self.excluded = excluded
  end

  def suitable?(word)
    letters = word.split("")
    positions = letters.each_index.select{ |i| letters[i] == letter }

    return false if self.positions.any? && (self.positions - positions).any?
    return false if excluded_positions.intersect?(positions)
    return false if included? && positions.empty?
    return false if excluded? && positions.any?
    true
  end

  def add_position!(index)
    self.included = true
    positions << index
    positions.uniq!
  end

  def exclude_position!(index)
    self.included = true
    excluded_positions << index
    excluded_positions.uniq!
  end
end

class WordMask
  attr_reader :mask

  def initialize(mask = {})
    @mask = mask
  end

  def [](letter)
    mask[letter] ||= LetterProps.new(letter)
  end

  def consume_round_mask!(checked_word, round_mask)
    for i in 0...5
      letter = checked_word[i]
      signal = round_mask[i]
      letter_props = self.[](letter)

      case signal
      when "0"
        letter_props.add_position!(i)
      when "1"
        letter_props.exclude_position!(i)
      when "2"
        letter_props.excluded = true
      end
    end
  end

  def filter_words(words)
    words.select do |word|
      mask.values.all? { |letter_props| letter_props.suitable?(word) }
    end
  end

  def with_compare_words(hidden, checked)
    new_mask = WordMask.new(mask.deep_dup)
    new_mask.tap { |mask| mask.compare_words!(hidden, checked) }
  end

  def compare_words!(hidden, checked)
    for i in 0...5
      letter = checked[i]
      letter_props = self.[](letter)
  
      if hidden.include?(letter)
        letter_props.included = true
      else
        letter_props.excluded = true
      end
  
      if hidden[i] == letter
        letter_props.add_position!(i) 
      else
        letter_props.exclude_position!(i) if letter_props.included?
      end
    end
  end
end

class Game
  attr_reader :mask, :filtered_words, :checked_word

  def initialize
    @mask = WordMask.new
    @filtered_words = WORDS
    @checked_word = FIRST_WORD
  end

  def next_round
    round_mask = prompt_round_mask
    mask.consume_round_mask!(checked_word, round_mask)
    @filtered_words = mask.filter_words(filtered_words)
    @checked_word = find_best
    puts "Next best word is #{@checked_word}"
  end

  def prompt_round_mask
    printf "Enter round mask (ex. 00120): "
    gets.chomp
  end

  private

  def find_best
    # because it checks only suitable here it works much faster but not ideally
    # especially when there are a lot of letters with position (ex вахта, тахта, бахта, шахта and mask *ахта)
    filtered_words.min_by.with_index do |checked, i|
      puts "#{i} / #{filtered_words.size}"

      filtered_words.sum do |hidden|
        mask = @mask.with_compare_words(hidden, checked)
        mask.filter_words(filtered_words).size
      end
    end
  end
end

puts "How to enter round mask:"
puts "  0 = letter at right position"
puts "  1 = there is letter in word but not on that position"
puts "  2 = there is no letter in word"
puts "Best first word is #{FIRST_WORD}"

game = Game.new

while true
  game.next_round
end
