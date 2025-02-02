module XCPretty
  class JSONCompilationDatabase < Reporter

    FILEPATH = 'build/reports/compilation_db.json'

    def load_dependencies
      unless @@loaded ||= false
        require 'fileutils'
        require 'pathname'
        require 'json'
        @@loaded = true
      end
    end

    def initialize(options)
      super(options)
      @compilation_units = []
      @pch_path = nil
      @current_file = nil
      @current_path = nil
    end

    def format_process_pch_command(file_path)
      @pch_path = file_path
    end

    def format_compile(file_name, file_path)
      @current_file = file_name
      @current_path = file_path
    end

    def format_compile_command(compiler_command, file_path)
      directory = file_path.gsub("#{@current_path}", '').gsub(/\/$/, '')
      directory = '/' if directory.empty?

      cmd = compiler_command
      cmd = cmd.gsub(/(\-include)\s.*\.pch/, "\\1 #{@pch_path}") if @pch_path

      @compilation_units << {arguments: cmd.split(' '),
                             file: @current_path,
                             directory: directory}
    end

    def format_swift_compile_command(compiler_command)
      directory = '/'

      cmd = compiler_command.split(/(?<!\\) /).map { |s| s.gsub(/\\/, '') }
      useless_args_count = cmd.index { |arg| arg.end_with?('swiftc') }
      cmd = cmd.drop(useless_args_count)
      input_file_list = cmd.find { |n| n.end_with?('SwiftFileList') }.delete_prefix("@")
      input_file_list_path = Pathname.new(input_file_list)
      
      input_file_list_path.each_line do |line|
        @compilation_units << {arguments: cmd,
                             file: line.chomp,
                             directory: directory} 
      end
      return EMPTY
    end

    def write_report
      File.open(@filepath, 'w') do |f|
        f.write(@compilation_units.to_json)
      end
    end
  end
end

