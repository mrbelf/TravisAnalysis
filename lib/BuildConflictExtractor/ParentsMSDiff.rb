require 'open-uri'
require 'rest-client'
require 'net/http'
require 'json'
require 'uri'

class ParentsMSDiff

	def initialize(gumTreePath)
		@gumTreePath = gumTreePath
	end

	def getGumTreePath()
		@gumTreePath
	end

	def runAllDiff(firstBranch, secondBranch)
		Dir.chdir getGumTreePath()
		mainDiff = nil
		modifiedFilesDiff = []
		addedFiles = []
		deletedFiles = []
		begin
			thr = Thread.new { diff = system "bash", "-c", "exec -a gumtree ./gumtree webdiff #{firstBranch.gsub("\n","")} #{secondBranch.gsub("\n","")}" }
			sleep(10)
			mainDiff = %x(wget http://127.0.0.1:4754/ -q -O -)
			modifiedFilesDiff = getDiffByModification(mainDiff[/Modified files \((.*?)\)/m, 1])
			addedFiles = getDiffByAddedFile(mainDiff[/Added files \((.*?)\)/m, 1])
			deletedFiles = getDiffByDeletedFile(mainDiff[/Deleted files \((.*?)\)/m, 1])
			
			kill = %x(pkill -f gumtree)
			sleep(5)
		rescue Exception => e
			puts "GumTree Failed"
		end
		return modifiedFilesDiff, addedFiles, deletedFiles
	end

	def verifyModifiedFile(baseLeftInitial, leftResultFinal, baseRightInitial, rightResultFinal)
		if(baseLeftInitial.size > 0)
			baseLeftInitial.each do |keyFile, fileLeft|
				fileRight = rightResultFinal[keyFile]
				if (fileRight == nil or fileLeft != fileRight)
					return false
				end
			end
		end
		if(baseRightInitial.size > 0) 
			baseRightInitial.each do |keyFile, fileRight|
				fileLeft = leftResultFinal[keyFile]
				if (fileLeft == nil or fileRight != fileLeft)
					return false
				end
			end
		end
		return true
	end

	def getDiffByModification(numberOcorrences)
		index = 0
		result = Hash.new()
		while(index < numberOcorrences.to_i)
			gumTreePage = Nokogiri::HTML(RestClient.get("http://127.0.0.1:4754/script?id=#{index}"))
			file = gumTreePage.css('div.col-lg-12 h3 small').text[/(.*?) \-\>/m, 1].gsub(".java", "")
			script = gumTreePage.css('div.col-lg-12 pre').text
			result[file.to_s] = script.gsub('"', "\"")
			index += 1
		end
		return result
	end

	def getDiffByDeletedFile(numberOcorrences)
		index = 0
		result = []
		while(index < numberOcorrences.to_i)
			gumTreePage = Nokogiri::HTML(RestClient.get("http://127.0.0.1:4754/"))
			gumTreePage.css('div#collapse-deleted-files table tr td').each do |element|
				result.push(element.text)
			end
			index += 1
		end
		return result
	end

	def getDiffByAddedFile(numberOcorrences)
		index = 0
		result = []
		while(index < numberOcorrences.to_i)
			gumTreePage = Nokogiri::HTML(RestClient.get("http://127.0.0.1:4754/"))
			gumTreePage.css('div#collapse-added-files table tr td').each do |element|
				result.push(element.text)
			end
			index += 1
		end
		return result
	end

end