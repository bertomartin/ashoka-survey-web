class Organization
  attr_reader :id, :name
  include Draper::Decoratable

  def initialize(id, name=nil)
    @id = id
    @name = name
  end

  def self.all(access_token, options={})
    return unless access_token
    organizations = access_token.get('/api/organizations').parsed.map { |org_json| json_to_organization(org_json) }
    organizations.reject { |org| org.id == options[:except] }
  end

  def self.json_to_organization(org_json)
    Organization.new(org_json['id'], org_json['name'])
  end

  def self.users(client, organization_id)
    if organization_id
      User.find_by_organization(client, organization_id)
    else
      []
    end
  end

  def self.publishable_users(client, organization_id)
    users(client, organization_id).select { |user| user.publishable? }
  end

  def self.exists?(client, org_ids)
    org_exists = client.get("/api/organizations/validate_orgs", :params => {:org_ids => org_ids.to_json})
    org_exists.parsed
  end

  def self.find_by_id(access_token, organization_id)
    begin
      organization_attrs = access_token.get("/api/organizations/#{organization_id}").parsed
      Organization.new(organization_attrs['id'], organization_attrs['name'])
    rescue OAuth2::Error
    end
  end

  def self.deleted_organizations
    response = HTTParty.get("#{ENV['OAUTH_SERVER_URL']}/api/deleted_organizations")
    JSON.parse(response.body).map { |id| Organization.new(id) }
  end

  def destroy!
    Survey.where(:organization_id => id).each { |survey| survey.delete_self_and_associated }
  end
end
