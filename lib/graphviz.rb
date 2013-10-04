# Copyright (c) 2013 Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "graphviz/version"

require "graphviz/graph"
require 'rexec'

module Graphviz
	class OutputError < StandardError
	end
	
	def self.output(graph, options = {})
		text = graph.to_dot
		
		output_format = options[:format]
		
		if options[:path]
			# Grab the output format from the file name:
			if options[:path] =~ /\.(.*?)$/
				output_format ||= $1
			end
			
			output_file = File.open(options[:path], "w")
		else
			output_file = IO.pipe
		end
		
		RExec::Task.open(["dot", "-T#{output_format}"], :out => output_file) do |task|
			task.input.puts(graph.to_dot)
			task.input.close
			
			status = task.wait
			
			if status != 0
				raise OutputError.new(task.error.read)
			end
			
			# Did we use a local pipe for output?
			if Array === output_file
				return task.output.read
			end
		end
	end
end