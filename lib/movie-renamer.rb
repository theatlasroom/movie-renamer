#!/usr/bin/ruby
#
#
#

require 'imdb'

module MovieRenamer
    
    NEWPATH = 'tmp'
    # TODO insert default
    @folderpath = '' 
    @is_a_test = false
    RENAMEPATTERN = ''
    MOVIEPATTERN = %r{\.((avi)|(mkv)|(mpg))$} 
    @input = STDIN
    @output = STDOUT



    class Movie
        
        def initialize(filename,year = '',director = '',title = '',part = '',imdb = nil)
            @year = year
            @director = director
            @title = title
            @part = part
            @imdb = imdb
            @filename = filename
        end

        attr_accessor :year, :director, :title, :part, :imdb, :filename

        def == (movie)
           if @year == movie.year and @director == movie.director and @title == movie.title and @part == movie.part and @imdb == movie.imdb and @filename == movie.filename
                return true
           else
                return false
           end
        end

    end

    # setters
    def MovieRenamer::folderPath=(folderpath)
        @folderpath = folderpath
    end


    #test helpers
    def MovieRenamer::input=(input)
        @input = input
    end

    def MovieRenamer::is_a_test=(input)
        @is_a_test = input
    end
    def MovieRenamer::output=(output)
        @output = output
    end

    # returns an array of filenames
    # TODO recursive find?
    def MovieRenamer::findMovies(folder = @folderpath)
        ar = Array.new
        Dir.open(folder) do |dir|
            dir.each do |file|
               if file =~ MOVIEPATTERN
                    ar << file
               end
            end
        end
        return ar.sort
    end

    # reads move filename and tries to initialize a movie object?
    # returns the movie object
    def MovieRenamer::readMovie(filename)
        # TODO insert logic here
        filename = File.basename(filename)
        title = File.basename(filename,'.*')
        return Movie.new(filename,'','', title)
    end

    # rename a movie according to movie data 
    # and moves it to the new path in filesystem 
    def MovieRenamer::renameMovie(movie,newpath = NEWPATH)
        filename = MovieRenamer::newName(movie)
        path = File.join(@folderpath,newpath)
        unless File.exist?(path)
            Dir.mkdir(path)   
        end

        begin 
            require 'fileutils'
            # remove noop
            return FileUtils::mv(File.join(@folderpath,movie.filename), File.join(path,filename), :noop => @is_a_test) ? true : false
        rescue SystemCallError => e
            puts e
        end
    end

    # plays the movie with mplayer
    def MovieRenamer::playMovie(movie)
        
    end

    # edit a movie interactively
    # read the movie
    # print movie info
    # ask movie data
    # rename movie
    # play movie option?
    # XXX add part integer check
    def MovieRenamer::editMovie(filename)
       movie = MovieRenamer::readMovie(filename)  
       MovieRenamer::printMovieInfo(movie)
       ans = askMore "would you like to edit this movie? [ yes, no, quit, info , play] "
       if ans 
           if ans == 'info'
             MovieRenamer::suggestMovies(movie.title) 
           elsif ans == 'play'
             MovieRenamer::playMovie(movie) 
           end
           #if ask "play movie with mplayer?" 
           #     MovieRenamer::playMovie(movie) 
           #end

           # TODO insert imdb suggestions here?
           
           @output.puts "Enter a year"
           movie.year = @input.gets.chomp.to_i

           @output.puts "Enter a director"
           movie.director = MovieRenamer::sanitizeInput(@input.gets.chomp)

           @output.puts "Enter a title"
           movie.title = MovieRenamer::sanitizeInput(@input.gets.chomp)

           @output.puts "Enter a part (you can leave this blank)"
           movie.part = MovieRenamer::sanitizeInput(@input.gets.chomp)
            

           MovieRenamer::printMovieInfo(movie)

           if ask "is this information correct" 
               return MovieRenamer::renameMovie(movie)
               #return true
           else
               editMovie(filename) 
           end
       else 
           return true
       end
       
    end

    
    # invoke edit movie on a whole folder
    def MovieRenamer::folderLoop(folder = @folderpath)
        MovieRenamer::findMovies(folder).each do |file|
            MovieRenamer::editMovie(file)
        end
    end


    def MovieRenamer::ask(question)
        @output.puts question
        response = @input.gets.chomp
        case response
        when /^y(es)?$/i
            true
        when /^no?$/i
            false
        else 
            puts "I don't understand. Please retry"
            ask(question)
        end
    end

    def MovieRenamer::askMore(question)
        @output.puts question
        response = @input.gets.chomp
        case response
        when /^y(es)?$/i
            true
        when /^no?$/i
            false
        when /^q(uit)?$/i
            exit 0
        when /^i(nfo)?$/i
            return "info"
        when /^p(lay)?$/i
            return "play"
        else 
            puts "I don't understand. Please retry"
            askMore(question)
        end
    end

    def MovieRenamer::printMovieInfo(movie)
        s = "Movie info is:\n"
        s+= "@oldfilename: #{movie.filename}\n"
        s+= "@year: #{movie.year}\n"
        s+= "@director: #{movie.director}\n"
        s+= "@title: #{movie.title}\n"
        s+= "@part: #{movie.part}\n"
        s+= "New filename = #{MovieRenamer::newName(movie)}\n"
        @output.puts s
        return s
    end

    # calculates new movie name based on a pattern? XXX
    # TODO change this and include a globalpattern
    def MovieRenamer::newName(movie)
        s = "#{movie.year} - #{movie.director} - #{movie.title}"        
        if movie.part =~ /\w/
            s+= " - part#{movie.part.to_i}"
        end
        s += File.extname(movie.filename)
        return s
    end


    def MovieRenamer::sanitizeInput(input)
        # XXX naive sanitize
        # simply removing all non standard characters
        input.gsub(/[^A-Za-z0-9\_\-\s]/,'').chomp.sub(/ +$/,'')
    end

    # makes a query to imdb database
    def MovieRenamer::suggestMovies(name)
        s = Imdb::Search.new(name) 
        s.movies.each do |m|
            @output.puts "#{m.year} - #{m.director.to_s.gsub(/(\[")|("\])/,'')} - #{m.title.gsub(/     .*/,'')}" 
        end
    end

    # TODO output string variable
    def MovieRenamer::suggestMovie(name)
        s = Imdb::Search.new(name) 
        m = s.movies.first
        @output.puts "#{m.year} - #{m.director} - #{m.title}" 
    end

    # returns the first movie from imdb query
    
end

