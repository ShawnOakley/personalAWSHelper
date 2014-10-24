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

@supportedStructures = ['EC2', 'dynamoDB', 'S3']
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



def checkInstancesByType(clientType)
	if !structureSupported?(clientType)
		raise "Specified client type not supported."
	end
	clientCreator(clientType)
	instanceInfo = checkInstances(clientType)
	return instanceInfo
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
	else
		raise "The specified client type is not currently supported."
	end
end

def checkDynamoDBInstances(options=nil)
	return @currentClients['dynamoDB'].tables
end

def checkEC2Instances(options=nil)
	return @currentClients['EC2'].instances
end

def checkS3Instances(options=nil)
	return @currentClients['S3'].buckets
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
			#NOTE : probably need to have resource specific formatting
			# for descriptions, broken down by network, architecture, etc.
			# puts item.methods
			# puts item.config
			# puts item.instance_variables
			# puts item.display
			# puts item.security_groups
			# puts item.network_interfaces
		end
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
		startMenu
	end

end

def startMenu
	puts "The following resources are available to you:"
	#NOTE: Need a formatting method
	puts gatherResources
	say("\nStart Menu")
	choose do |menu|
		menu.index        = :letter
		menu.index_suffix = ") "

		menu.prompt = "What would you like to do?"
		
		menu.choice ("This is a choice") do 
			say("Good choice!") 
		end
		
		menu.choice("This too") do 
			say("Not from around here, are you?") 
		end
	end
	# checkStatusAll
end

# initializeClient(configHash)
# puts structureSupported?('ec2')

startCLI