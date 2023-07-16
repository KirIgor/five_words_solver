WORDS = File.read("dict.txt").split("\n")
FIRST_WORD = "океан" # find_best({})

def check_letter(word, letter, value)
  case value
  when Array
    value.all? { |pos| word[pos] == letter }
  when "+"
    word.include?(letter)
  when "-"
    !word.include?(letter)
  else
    true
  end
end

def check_word(word, mask)
  mask.all? { |letter, value| check_letter(word, letter, value) }
end

def get_suitable_words(suitable, mask)
  suitable.select { |x| check_word(x, mask) }
end

def calculate_mask(hidden, checked)
  checked.split("").uniq.each_with_object({}) do |letter, res|
    res[letter] = hidden.split("").filter_map.with_index { |x, i| i if x == letter }
    res[letter] ||= "+" if hidden.include?(letter)
    res[letter] ||= "-"
  end
end

def find_best(mask)
  suitable = get_suitable_words(WORDS, mask)
  # because it checks only suitable here it works much faster but not ideally
  # especially when there are a lot of letters with position (ex вахта, тахта, бахта, шахта and mask *ахта)
  suitable.min_by.with_index do |checked, i|
    puts "#{i} / #{suitable.size}"

    suitable.sum do |hidden|
      get_suitable_words(suitable, calculate_mask(hidden, checked)).size
    end
  end
end

def prompt_mask
  res = {}

  printf "Enter word mask (ex. \"*а**р\"): "
  pos = gets.chomp
  pos.split("").each.with_index do |letter, i|
    next if letter == "*"
    res[letter] ||= []
    res[letter] << i
  end

  printf "Enter letters in word without known positions (ex. \"шфрыв\"): "
  included = gets.chomp
  included.split("").each { |x| res[x] ||= "+" }

  printf "Enter letters not in word (ex. \"шфрыв\"): "
  excluded = gets.chomp
  excluded.split("").each { |x| res[x] ||= "-" }

  res
end

puts "Best first word is #{FIRST_WORD}"

while true
  mask = prompt_mask
  puts find_best(mask)
end