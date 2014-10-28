require 'json'
require 'aws-sdk'
require 'highline/import'

# json = File.open('../AWS.json').read
# configHash = JSON.parse(json)

# Create config hash for more readable code within functions

# formattedConfigHash = {
#   	access_key_id: configHash["AWSAccessKey"],
#   	secret_access_key: configHash["AWSSecretKey"],
#   	region:	configHash["defaultRegion"]
# }

# May want an instance to track initialized clients
# Don't need ID b/c there should only be one instance of each type,
# as initialized
# E.g.: [{'clientType': 'EC2', 'clientInstance': client}]
# Initialize to nil

@supportedStructures = ['EC2', 'dynamoDB', 'S3', 'IAM']
@currentClients = {}

@supportedStructures.each do |struct|
	@currentClients[struct] = nil;
end

def initializeClient(formattedConfigHash)
	AWS.config(formattedConfigHash)
end

def clientCreator(clientType, formattedConfigHash = nil)
	# puts 'clientCreator call'
	# puts clientType
	if !structureSupported?(clientType)
		raise "Specified client not supported."
	end

	if @currentClients[clientType]
		return @currentClients[clientType]
	end

	case clientType

	when "EC2"
		@currentClients["EC2"] = ec2create(formattedConfigHash)
	when "dynamoDB"
		@currentClients["dynamoDB"] = dynamoDBcreate(formattedConfigHash)
	when "S3"
		@currentClients["S3"] = s3create(formattedConfigHash)
	when 'IAM'
		@currentClients["IAM"] = IAMcreate(formattedConfigHash)
	else
		raise "The specified client type is not currently supported."
	end
	# puts @currentClients

end

def optionsParser(optionsHash)

end

def dynamoDBcreate(formattedConfigHash)
	if !configExists?
		client = AWS::DynamoDB.new(formattedConfigHash)
	else 
		client = AWS::DynamoDB.new
	end
	return client
end

def s3create(formattedConfigHash)
	if !configExists?
		client = AWS::S3.new(formattedConfigHash)
	else 
		client = AWS::S3.new
	end
	return client
end

def ec2create(formattedConfigHash)
	if !configExists?
		client = AWS::EC2.new(formattedConfigHash)
	else 
		client = AWS::EC2.new
	end
	return client
end

def IAMcreate(formattedConfigHash)
	if !configExists?
		client = AWS::IAM.new(formattedConfigHash)
	else 
		client = AWS::IAM.new
	end
	return client
end

def checkInstances(clientType, options = nil)
	#handle the various types of calls to return instance info
	#depends on type of client
	if !@currentClients[clientType]
		clientCreator(clientType)
	end

	# puts "checkInstances call"

	case clientType

	when "EC2"
		return checkEC2Instances(options)
	when "dynamoDB"
		return checkDynamoDBInstances(options)
	when "S3"
		return checkS3Instances(options)
	when "IAM"
		return checkIAM(options)
	else
		raise "The specified client type is not currently supported."
	end
end

def checkDynamoDBInstances(options=nil)
	return @currentClients['dynamoDB'].tables
	# .inject({}) { |m, i| m[i.id] = i.status; m }
end

def checkEC2Instances(options=nil)
	return @currentClients['EC2'].instances
	# .inject({}) { |m, i| m[i.id] = i.status; m }
end

def checkS3Instances(options=nil)
	return @currentClients['S3'].buckets
	# .inject({}) { |m, i| m[i.id] = i.status; m }
end

def checkIAM(options=nil)
	return @currentClients['IAM'].account_summary
end


def checkStatusAll(configHash = nil)

	if !configExists? && (configHash == nil)
		raise "Client needs to be defined."
	end

	# puts @supportedStructures

	@supportedStructures.each do |struct|
		# puts 'CheckStatusAll each block'
		# puts struct
		clientCreator(struct)
	end

	@supportedStructures.each do |struct|
		checkInstances(struct).each do |item|
			formatItem(struct, item)
		end
	end	

end

def formatItem(clientType, instance)

	if !@currentClients[clientType]
		clientCreator(clientType)
	end

	# puts "checkInstances call"

	case clientType

	when "EC2"
		puts @currentClients["EC2"].instances.inject({}) { |m, i| m[i.id] = i.status; m }
	when "dynamoDB"
		@currentClients["dynamoDB"].tables.each do |table|
			puts table.name
		end
	when "S3"
		@currentClients["S3"].buckets.each do |bucket|
  			puts bucket.name
		end
	when "IAM"
		# return checkIAM(options)
	else
		raise "The specified client type is not currently supported."
	end

end

def gatherResources(clientType=nil)
	availableResources = []
	if !(clientType)
		@supportedStructures.each do |struct|
			checkInstances(struct).each do |item|
				availableResources << item
			end
		end	
	else
		checkInstances(clientType)
	end


	return availableResources
end


# Helper functions to check current state of config/script capabilities

def configExists?
	return !!(AWS)
end

def structureSupported?(structure)
	# puts 'structureSupported? call' 
	# puts structure
	# puts @supportedStructures
 return @supportedStructures.include?(structure)
end

# CLI Highline scripting functions

def startCLI

	jsonFile = ask("Please specify path to key/secret JSON.") do |q|
		q.default = "../AWS.json"
    	q.readline = true
	end
  	say("Checking \"#{jsonFile}\"")
  	json = File.open(jsonFile).read
	configHash = JSON.parse(json)
	
	formattedConfigHash = {
  		access_key_id: configHash["AWSAccessKey"],
  		secret_access_key: configHash["AWSSecretKey"],
  		region:	configHash["defaultRegion"]
	}

	initializeClient(formattedConfigHash)

	# NOTE: Needs error handling
	if AWS
		startMenuCLI
	end

end

def startMenuCLI
	puts "The following resources are available to you:"
	#NOTE: Need a formatting method
	gatherResources()
	checkStatusAll()
	say("\nStart Menu")
	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "What would you like to do?"
		
		menu.choice ("Initialize a new resource") do 
			resourceInitializationCLI
		end
		
		menu.choice("Inspect current resources.") do 
			resourceInspectionCLI 
		end

		menu.choice("Spin down or delete a current resource.") do
			resourceTerminationCLI
		end

		menu.choice("Alter or configure current resources.") do
			resourceConfigurationCLI
		end

		menu.choice("Upload or delete content from current resource") do
			dataAlterationCLI
		end

		menu.choice("Configure/Set Security groups") do
			securityGroupsCLI
		end

		menu.choice("Quit") do
			quitCLI
		end

	end
	# checkStatusAll
end

def resourceInitializationCLI

	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "What kind of resource would you like to initialize?"
		
		menu.choice ("S3") do 
			# S3Initialize
			S3InitializationCLI()
		end
		
		menu.choice("EC2") do 
			# EC2Initialize
			EC2InitializationCLI() 
		end

		menu.choice("DynamoDB") do
			# dynamoDBInitialize
			dynamoDBInitializationCLI()
		end

		menu.choice("Back") do
		end

		menu.choice("Quit") do
		end

	end

end

def S3InitializationCLI

	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "S3 Initialization Options"

		# Need to intialize a 'bucket array' to give 
		# choices for selection
		
		menu.choice ("Create a new S3 bucket.") do 
			bucketName = ask("Enter the name of your new bucket:  ")
			puts "Creating #{bucketName}..."
			S3BucketCreate(bucketName)
			startMenuCLI
		end
		
		menu.choice("Create a new directory in an existing S3 bucket.") do 
			bucketChoices = checkInstances('S3')
			puts "You can choose from the following buckets: "
			bucketChoices.each do |bucket|
				puts bucket
			end
		end

		menu.choice("Back") do
		end

		menu.choice("Quit") do
		end

	end

end

def S3Initialize

	@currentClients['S3'].new()

end

def S3BucketCreate(bucketName, options=nil)
	@currentClients['S3'].buckets.create(bucketName)
end

def EC2InitializationCLI

	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "EC2 Initialization Options"

		# Need to intialize a 'bucket array' to give 
		# choices for selection
		
		menu.choice ("Create a new EC2 instance.") do 
			EC2InstanceCreate()
			startMenuCLI()
		end

		menu.choice("Back") do
			# NEED BACK OPTION HERE
		end

		menu.choice("Quit") do
		end

	end

end

def EC2InstanceCreate(image_id = "ami-8c1fece5", option=nil)
	@currentClients['EC2'].instances.create(:image_id => image_id)
end

def dynamoDBInitializationCLI()

	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "DynamoDB Initialization Options"

		# Need to intialize a 'bucket array' to give 
		# choices for selection
		
		menu.choice ("Create a new DynamoDB Table.") do 
			dynamoDBCreate()
			startMenuCLI()
		end

		menu.choice("Back") do
			# NEED BACK OPTION HERE
		end

		menu.choice("Quit") do
		end

	end

end

def dynamoDBCreate(tableName='defaultTableName', x=10,y=5,hash_key={id: :string })
	table = @currentClients['dynamoDB'].tables.create(
  		tableName, x, y,
  	hash_key: hash_key
	)
	sleep 1 while table.status == :creating
end

def resourceInspectionCLI

end

def resourceTerminationCLI

end

def resourceConfigurationCLI

end

def dataAlterationCLI

end

def securityGroupsCLI

end

def quitCLI

end

# initializeClient(configHash)
# puts structureSupported?('ec2')

startCLI