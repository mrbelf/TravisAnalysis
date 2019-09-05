class IncompatibleTypes

	def initialize()
		
	end

	def extractionFilesInfo(buildLog)
		filesInformation = []
		logs = buildLog.to_enum(:scan, /^[\--z ]+:[\[]?[\d\,]+[\]]?[\:]? error: incompatible types: \w+ cannot be converted to \w+$/).map { Regexp.last_match }
		begin
			if (buildLog[/^[\--z ]+:[\[]?[\d\,]+[\]]?[\:]? error: incompatible types: \w+ cannot be converted to \w+$/])
				count = 0
				while (count < logs.size)
					if(logs[count].to_s[/\[/].nil?)					
						line = logs[count].to_s[/\.java:\d+/].split(":").last
						classFile = logs[count].to_s[/[\/\-\_\w]+\.java:/].split("/").last.gsub(".java:","")
						typeAndExpected = logs[count].to_s[/\w+ cannot be converted to \w+/].to_s.split(" ")
						type = typeAndExpected[0]
						expectedType = typeAndExpected[5]
						filesInformation.push(["IncompatibleTypes",classFile, type, expectedType,line.to_i])
					else
						line = logs[count].to_s[/\.java:\[\d+/].split("[")[1]
						classFile = logs[count].to_s[/[\/\-\_\w]+\.java:/].split("/").last.gsub(".java:","")
						typeAndExpected = logs[count].to_s[/\w+ cannot be converted to \w+/].to_s.split(" ")
						type = typeAndExpected[0]
						expectedType = typeAndExpected[5]
						column = logs[count].to_s[/\.java:\[\d+,\d+/].split(",")[1]
						filesInformation.push(["IncompatibleTypes",classFile, type, expectedType,line.to_i,column.to_i])
					end

					count += 1
				end
			end	
			return "IncompatibleTypes", filesInformation, logs.size
		rescue
			return "IncompatibleTypes", [], 0
		end
	end

	#considerando uma única String como entrada, e com informação de coluna
	def findVariableMethod (erroredLine,column, javaClass)
		count = 0
		var = ""
		changedMethod = ""
		javaClass.each_line do |line|
			count += 1
			if(count == erroredLine)
				line = line.split(".")
				var = line[line.size-2].gsub(" ","").gsub("	","")
				changedMethod = ""
				line[line.size-1].each_char do |char|
					if(char != '(')
						changedMethod = changedMethod + char
					else
						break
					end
				end
			end
			
		end
		return [var,changedMethod]
	end

end
