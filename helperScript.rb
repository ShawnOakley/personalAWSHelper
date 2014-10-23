require 'json'
require 'aws-sdk'

json = File.open('../AWS.json').read
configHash = JSON.parse(json)

# Create config hash for more readable code within functions

formattedConfigHash = {
  	access_key_id: configHash["AWSAccessKey"],
  	secret_access_key: configHash["AWSSecretKey"],
  	region:	configHash["defaultRegion"]
}

def initializeClient(formattedConfigHash)
	AWS.config(formattedConfigHash)
end

def clientCreator(clientType, formattedConfigHash = nil)

	case clientType

	when "ec2"
		client = ec2create(formattedConfigHash)
	when "dynamoDB"
		client  = dynamoDBcreate(formattedConfigHash)
	when "s3"
		client = s3create(formattedConfigHash)
	else
		raise "The specified client type is not currently supported."
	end

	return client

end

def optionsParser(optionsHash)

end

def configExists?
	return !!(AWS)
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
end

def checkS3buckets(configHash)

end

def checkEC2(configHash)

end

def summarizeStates(configHash = nil)
	if (AWS == nil) && (configHash == nil)
		raise "Client needs to be defined."
	else
		supportedStructures.each do |struct|
			clientCreator(struct)
		end
	end

end

initializeClient(configHash)