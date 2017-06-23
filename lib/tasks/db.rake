require 'rbconfig'
require 'rake/testtask'

class TestTaskWithoutDescription < Rake::TestTask
# Create the tasks defined by this task lib.
  def define
    lib_path = @libs.join(File::PATH_SEPARATOR)
    task @name do
    run_code = ''
    RakeFileUtils.verbose(@verbose) do
      run_code =
      case @loader
      when :direct
        "-e 'ARGV.each{|f| load f}'"
      when :testrb
        "-S testrb #{fix}"
      when :rake
        rake_loader
      end
      @ruby_opts.unshift( "-I\"#{lib_path}\"" )
      @ruby_opts.unshift( "-w" ) if @warning
      ruby @ruby_opts.join(" ") +
        " \"#{run_code}\" " +
        file_list.collect { |fn| "\"#{fn}\"" }.join(' ') +
        " #{option_list}"
      end
    end
    self
  end
end

namespace :dbtest do
  TestTaskWithoutDescription.new(:units => :environment) do |t|
    t.libs << "test"
    t.pattern = 'test/unit/**/*_test.rb'
  end

  TestTaskWithoutDescription.new(:functionals => :environment) do |t|
    t.libs << "test"
    t.pattern = 'test/functional/**/*_test.rb'
  end

end

