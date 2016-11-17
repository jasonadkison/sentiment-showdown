class Showdown
  include CommandLineReporter
  require "yaml"
  require "uri"

  EXAMPLES_FILE = "data/sentiment.yml".freeze

  def initialize
    self.formatter = 'nested'
    self.formatter.complete_string = 'done'

    # load the examples from yaml
    @examples = YAML.load(File.read(EXAMPLES_FILE))
    aligned "Loaded examples from #{EXAMPLES_FILE}"

    # setup results template
    @results = {}
    %w(sentimental sentimentalizer alchemy microsoft).each do |subject|
      @results[subject] = {}
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

    report(:message => 'Sentimental Showdown!') do
      sleep 0.25

      report(:message => 'Sentimental') do
        sleep 0.10
        run_sentimental
      end

      report(:message => 'Sentimentalizer') do
        sleep 0.10
        run_sentimentalizer
      end

      report(:message => 'AlchemyAPI') do
        sleep 0.10
        run_alchemy
      end

      report(:message => 'MS Text Analytics API') do
        sleep 0.10
        run_microsoft
      end

    end

    display_results
  end

  private

  def reset_results
    @results.keys.each do |subject|
      @examples.keys.each do |sentiment_type|
        @results[subject][sentiment_type] = { 'expected' => @examples[sentiment_type].size, 'result' => 0 }
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
          sentiment = @sentimentalizer.analyze(items[i]).sentiment.to_s
          report(:message => items[i], type: "inline", :complete => sentiment) do
            @results['sentimentalizer'][sentiment.to_s]['result'] += 1 if sentiment == type
            sleep 0.15
          end
        end

      end
    end
  end

  def run_alchemy

    @results['alchemy'].keys.each do |type|
      report(:message => type) do
        items = @examples[type]
        total_items = items.size

        total_items.times do |i|
          sentiment = Unirest.get("https://alchemy.p.mashape.com/text/TextGetTextSentiment?outputMode=json&showSourceText=false&text=#{URI.escape(items[i])}",
                        headers: {
                          "X-Mashape-Key" => MASHAPE_KEY,
                          "Accept" => "text/plain"
                        }).body['docSentiment']['type'] rescue ''

          report(:message => items[i], type: "inline", :complete => sentiment) do
            @results['alchemy'][sentiment.to_s]['result'] += 1 if sentiment == type
            sleep 0.15
          end
        end

      end
    end

  end

  def run_microsoft
    @results['microsoft'].keys.each do |type|
      report(:message => type) do
        items = @examples[type]
        total_items = items.size

        sentiments = Unirest.post("https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/sentiment",
                      headers: {
                        "Ocp-Apim-Subscription-Key" => MICROSOFT_KEY,
                        "Content-Type" => "application/json",
                        "Accept" => "application/json"
                      },
                      parameters: {
                        :documents => items.each_with_index.map { |item, index| { :language => :en, :id => index, :text => item } }
                      }.to_json).body['documents'].map { |result|
                        score = result['score'].to_f.round(2)
                        if score < 0.33
                          'negative'
                        elsif score >= 0.33 && score < 0.66
                          'neutral'
                        elsif score >= 0.66
                          'positive'
                        else
                          "unknown"
                        end
                      }

        total_items.times do |i|
          report(:message => items[i], type: "inline", :complete => sentiments[i]) do
            @results['microsoft'][sentiments[i].to_s]['result'] += 1 if sentiments[i] == type
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
       column('CALCULATOR', :width => 25)
       column('NEGATIVES', :width => 25)
       column('NEUTRALS', :width => 25)
       column('POSITIVES', :width => 25)
     end

     @results.keys.each do |subject|
       row do
         column subject
         column "#{@results[subject]['negative']['result']}/#{@results[subject]['negative']['expected']}"
         column "#{@results[subject]['neutral']['result']}/#{@results[subject]['neutral']['expected']}"
         column "#{@results[subject]['positive']['result']}/#{@results[subject]['positive']['expected']}"
       end
     end

   end
  end

end
