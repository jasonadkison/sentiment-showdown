class Showdown
  include CommandLineReporter
  require "yaml"

  EXAMPLES_FILE = "data/sentiment.yml".freeze

  def initialize
    self.formatter = 'nested'
    self.formatter.complete_string = 'done'

    # load the examples from yaml
    @examples = YAML.load(File.read(EXAMPLES_FILE))
    aligned "Loaded examples from #{EXAMPLES_FILE}"

    # setup results template
    @results = {}
    %w(sentimental sentimentalizer).each do |gem_name|
      @results[gem_name] = {}
    end

    # setup sentimental
    @sentimental = Sentimental.new
    @sentimental.load_defaults
    @sentimental.threshold = 0.1

    # setup sentimentalizer
    Sentimentalizer.setup
    @sentimentalizer = Sentimentalizer

    horizontal_rule(:width => 20)
  end

  def run
    reset_results

    report(:message => 'Sentimental vs. Sentimentalizer') do
      sleep 0.25

      report(:message => 'Sentimental') do
        sleep 0.25
        run_sentimental
      end

      report(:message => 'Sentimentalizer') do
        sleep 0.25
        run_sentimentalizer
      end
    end

    display_results
  end

  private

  def reset_results
    @results.keys.each do |gem_name|
      @examples.keys.each do |sentiment_type|
        @results[gem_name][sentiment_type] = { 'expected' => @examples[sentiment_type].size, 'result' => 0 }
      end
    end
  end

  def run_sentimental
    @results['sentimental'].keys.each do |type|
      report(:message => type) do
        items = @examples[type]
        total_items = items.size

        total_items.times do |i|
          sentiment = @sentimental.sentiment(items[i]).to_s
          report(:message => items[i], type: "inline", :complete => sentiment) do
            @results['sentimental'][sentiment.to_s]['result'] += 1 if sentiment == type
            sleep 0.15
          end
        end

      end
    end
  end

  def run_sentimentalizer
    @results['sentimentalizer'].keys.each do |type|
      report(:message => type) do
        items = @examples[type]
        total_items = items.size

        total_items.times do |i|
          sentiment = @sentimentalizer.analyze(items[i]).sentiment
          report(:message => items[i], type: "inline", :complete => sentiment) do
            @results['sentimentalizer'][sentiment.to_s]['result'] += 1 if sentiment == type
            sleep 0.15
          end
        end

      end
    end
  end

  def display_results
    horizontal_rule(:width => 20)
    aligned "Results"

    table(:border => true) do
     row do
       column('GEM', :width => 20)
       column('EXPECTED NEGATIVES', :width => 20)
       column('RESULTING NEGATIVES', :width => 20)
       column('EXPECTED NEUTRALS', :width => 20)
       column('RESULTING NEUTRALS', :width => 20)
       column('EXPECTED POSITIVES', :width => 20)
       column('RESULTING POSITIVES', :width => 20)
     end

     @results.keys.each do |gem_name|
       row do
         column gem_name
         column @results[gem_name]['negative']['expected']
         column @results[gem_name]['negative']['result']
         column @results[gem_name]['neutral']['expected']
         column @results[gem_name]['neutral']['result']
         column @results[gem_name]['positive']['expected']
         column @results[gem_name]['positive']['result']
       end
     end

   end
  end

end
