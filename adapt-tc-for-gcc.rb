#!/usr/bin/ruby

class String
	def is_include_statement
		self =~ /^#include( )?<[a-z]+(\.h)?>$/
		not $~.nil?
	end

	def transform_include_statement
		self =~ /^#include( )?<([a-z]+(\.h)?)>$/
		raise if $~.nil?

		$INCLUDE_TR = {
			'iostream.h' => 'iostream'
		}

		repl = $INCLUDE_TR[$2]
		raise 'unhandled include file, add it to $INCLUDE_TR' if repl.nil?

		self.replace('#include <' + repl + '>')
	end
end

raise if ARGV.size != 1
File.open(ARGV[0], 'r') do |f|
	@a = f.readlines
end

@input_a = @a.clone

@line_breaks = :unknown
@line_breaks = :dos if @a[0] =~ /\r\n$/

raise if @line_breaks == :unknown

@a.each do |ln|
	ln.gsub!(*case @line_breaks
		when :dos then [/^(.*)\r\n$/, '\1']
		else raise
	end)
end

@a.each do |ln|
	raise 'trailing whitespace' if ln != ln.rstrip
end

#==================================

n_includes = @a.select{|ln| ln.is_include_statement }.size
@a[0...n_includes].each do |ln|
	raise if not ln.is_include_statement
end

@a[0...n_includes].each do |ln|
	ln.transform_include_statement
end

@a = @a[0...n_includes] + ["using namespace std;"] + @a[n_includes...@a.size]

@a.each do |ln|
	if ln =~ /^void main\(\)$/
		ln.replace('void __user_main()')
		break
	end
end

@a << 'int main() { __user_main(); return 0; }'

#==================================

puts "Line breaks: #{@line_breaks.to_s}"
puts "Files \#included: #{n_includes}"
puts "Input lines: #{@input_a.size}"
puts "Output lines: #{@a.size}"

File.open(ARGV[0], 'w') do |f|
	@a.each {|ln| f.puts ln}
end

puts "Result written to #{ARGV[0]}"
