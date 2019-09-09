class IncompatibleTypes

	def initialize()
		
	end

	def extractionFilesInfo(buildLog, pathProject)
		pathAtual = Dir.pwd
		projectName = pathProject.split("/").last
		Dir.chdir pathProject
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
						javaFile = classFile + ".java"
						files = %x(find -name #{javaFile})
												
						erroredClass = findAttributeType(removeComments(javaClass), findClass(javaClass)[0], findVariable(line,-1,javaClass), line, thisWasUsed(line,-1,javaClass, it.findVariable(line,-1,javaClass)))

						filesInformation.push(["IncompatibleTypes",classFile, type, expectedType,line.to_i, erroredClass])
					else	
						line = logs[count].to_s[/\.java:\[\d+/].split("[")[1]
						classFile = logs[count].to_s[/[\/\-\_\w]+\.java:/].split("/").last.gsub(".java:","")
						typeAndExpected = logs[count].to_s[/\w+ cannot be converted to \w+/].to_s.split(" ")
						type = typeAndExpected[0]
						expectedType = typeAndExpected[5]
						column = logs[count].to_s[/\.java:\[\d+,\d+/].split(",")[1]
						javaFile = classFile + ".java"
						files = %x(find -name #{javaFile})
						finalFile = ""
						files.each_line do |file|
							pathInProject = ""
							log = logs[count].to_s[/#{projectName}[\/\w\-]+\.java/][0].to_s.split("/")
							i = 1
							log.each do |str|
								if(log.size != i)
									pathInProject = pathInProject + str + "/"
								end
								i += 1
							end
							if(file.include?(pathInProject))
								finalFile = file
								break
							end
						end

						finalDir = ""
						i = 1
						finalFile.split("/").each do |str|
							if(i != finalFile.split("/").size)
								finalDir = finalDir + str + "/"
							end 
						i += 1
						end
						Dir.chdir finalDir
						javaClass = ""
						puts finalDir
						File.open(javaFile).each do |line|
							javaClass = javaClass + line
						end
						javaClass = removeComments(javaClass)
						classStartsAt = findClass(javaClass)
						variableName = findVariable(line,column,javaClass)
						puts "got here" 
						puts classStartsAt[0]
						erroredClass = findAttributeType(javaClass, classStartsAt[0].to_i, variableName, line.to_i, thisWasUsed)
						puts erroredClass
						filesInformation.push(["IncompatibleTypes",classFile, type, expectedType,line.to_i,column.to_i,erroredClass])
					end

					count += 1
				end
			end	
			return "IncompatibleTypes", filesInformation, logs.size
		rescue
			return "IncompatibleTypes", [], 0
		end
	end

	def findVariable (erroredLine,column, javaClass)
		erroredLine = erroredLine.to_i
		var = ""
		changedMethod = ""
		javaClass = javaClass.split("\n")
		line = javaClass[erroredLine-1].split(".")
		var = line[line.size-2].gsub(" ","").gsub("	","")
		return var	
	end

	def thisWasUsed (erroredLine, column, javaClass, var)
		return !javaClass.split("\n")[erroredLine-1][/this\.#{var}\.\w+/].nil?
	end

	def removeComments(javaClass)
		finalJavaClass = ""
		commentedLine = false
		commentedBlock = false
		singleSlash = false
		singleAsterisk = false
		javaClass.each_char do |char|
			if(char == "/" || char == "*")
				if(char == "*" && singleSlash)
					singleSlash = false
					commentedBlock = true
				elsif(char == "/" && singleAsterisk)
					singleAsterisk = false
					commentedBlock = false
					next
				elsif(char == "/" && singleSlash)
					singleSlash = false
					commentedLine = true
				elsif(char == "*")
					singleAsterisk = true
					next
				else
					singleSlash = true
					next
				end
			else
				if(!commentedLine && !commentedBlock)
					if(singleSlash)
						finalJavaClass = finalJavaClass + "/"
					elsif(commentedLine)
						finalJavaClass = finalJavaClass + "*"
					end
				end
				singleSlash = false
				singleAsterisk = false
			end
		
			if(commentedLine)
				if(char == "\n")
					finalJavaClass = finalJavaClass + char
					commentedLine = false
				else
					next
				end
			elsif(commentedBlock)
				if(char == "\n")
					finalJavaClass = finalJavaClass + char
				else
					next
				end	
			else
				finalJavaClass = finalJavaClass + char
			end		
		end
		return finalJavaClass
	end

	def findClass(javaClass)
		returnLine = -1
		count = 0
		found = false
		javaClass.each_line do |line|
			if(line[/public[\ ]+class[\ ]+\w+ [\w0-9\ \_\-]+{/] || line[/private[\ ]+class[\ ]+\w+ [\w0-9\ \_\-]+{/] || line[/protected[\ ]+class[\ ]+\w+ [\w0-9\ \_\-]+{/])
				if(found)
					return [-1,false]
				else
					returnLine = count
					found = true
				end
			end
			count += 1
		end
		return [returnLine,true]
	end

	def findAttributeType(javaClass,classStartsAt,var,erroredLine, thisWasUsed)
		javaClass = javaClass.split("\n")
		found = false
		type = ""
		count = classStartsAt+1
		begin
			while(!found)
				if(javaClass[count].include?("{") || javaClass[count].include?("}"))
					return ["",false]
				end
				if(count >= erroredLine)
					return ["",false]
				end
				if(!javaClass[count][/private[\ ]+\w+[\ ]+#{var}/].nil?)
					return [javaClass[count].split(" ")[1],true&&thisWasUsed]
				end
			count += 1
			end
			return ["",false]
		rescue
			return ["",false]
		end
	end
end




test = ""
File.open("test.txt").each do |line|
	test = test + line
end

it = IncompatibleTypes.new()

info1 = it.extractionFilesInfo(test, "/home/ines/Documents/neo4j-timetree")
puts info1
