#!/usr/bin/env ruby
#file: mergeCommit.rb

require 'travis'
require 'csv'
require 'rubygems'
require 'fileutils'
require 'find'
require 'octokit'
require 'github_api'
require 'json'
require 'find'
require 'fileutils'

class MergeCommit

	def initialize()
		@parentsCommit = []
	end

	def getParentsMergeIfTrue(pathProject, commit)
		Dir.chdir pathProject.gsub('.travis.yml','')
		commitType = %x(git cat-file -p #{commit})
		commitType.each_line do |line|
			if(line.include?('author'))
				break
			end
			if(line.include?('parent'))
				@parentsCommit.push(line.partition('parent ').last.gsub('\n','').gsub(' ',''))
			end
		end

		if (@parentsCommit.length > 1)
			return @parentsCommit
		else
			return nil
		end
	end

	def getTypeConflict(pathProject, commit)
		Dir.chdir @pathProject
		filesConflict = %x(git diff --name-only #{@commit}^!)
		statusConfig = true
		if (filesConflict == ".travis.yml\n")
			return "Travis"
		else
			filesConflict.each_line do |newLine|
				if (!newLine[/.*pom.xml\n*$/] and !newLine[/.*build.gradle\n*$/])
					statusConfig = false
					break
				end
			end

			if (statusConfig)
				return "Config"
			else
				if (filesConflict.include?('pom.xml') || filesConflict.include?('build.gradle') || filesConflict.include?('.travis.yml') || filesConflict.include?('.java'))
					return "All"	
				else
					return "SourceCode"
				end
			end
		end
	end

end