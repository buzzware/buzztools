# from https://github.com/buzzware/buzztools/blob/master/lib/buzztools/versionary.rb
# Versionary is a mixin for implementing versioning of models with ActiveRecord in Rails 3.2+
# It attempts to be better than other solutions eg.
#
# * no shadow tables
# * does not abuse ActiveRecord, no magic
# * no serialization at all, so queries work with all versions
# * associations work like normal ActiveRecord. The id column identifies a single version of an instance. You can associate to an old version
# * its easy to read and write old versions
# * if you use and keep updated the ver_current column, it is extremely fast
# * this file is really all there is to it
# * supports future versions that become current when the time comes eg. future price changes
#
# This is achieved by using the id column to identify each version of each instance, unlike some solutions that use the id per instance, then have to do trickery to provide versions.
# This means associations can simply attach to any version of any instance using the id column as normal
# Instances are identified by the iid column
#
# id    iid  version   name  price
# 1     3         1         eggs  2.99
# 2     3         2         eggs  3.10
# 3     4         1         bread 3.50
#
# In the above table, eggs (iid = 3) has 2 versions and bread (iid = 4) has 1 version.
# An order can simply attach to any product/version using the id column
#
# The eggs product would be created as follows :
#
# eggs = Product.create!(name: 'eggs', price: 2.99)
# eggs2 = eggs.create_version!(price: 3.10)
#
# current_10_dollar_products = Product.live_current_versions.where(price: 10)
#
# Migration
#
#class CreateThings < ActiveRecord::Migration
#  def change
#    create_table :things do |t|
#      t.integer :iid         # instance id - versions of an instance will have different ids but the same iid
#      t.integer :version
#      t.integer :current_from, limit: 8    # timestamp in milliseconds since 1970
#			 t.boolean :ver_current, null: false, default: false    # optional, for performance. true indicates this is the current version
#
#      t.integer :size
#      t.string :colour
#      t.string :shape
#    end
#		add_index(:things, [:iid, :version], :unique => true)
#  end
#end
#
# Model
#
#class Thing < ActiveRecord::Base
#
#	include Versionary
#
#end
#
#
module Versionary

	def self.included(aClass)
    aClass.class_eval do

	    def self.next_version_id(aIid)
	   		where(iid: aIid).maximum(:version).to_i + 1
	   	end

	    after_create do
	   		updates = {}
	   		updates[:iid] = id if !iid
		    if !version
	   		  updates[:version] = self.class.next_version_id(self.iid)
		    end
	   		update_attributes!(updates) unless updates.empty?
	   		true
	   	end

			# should be able to do eg. : TaxRate.where(owner_id: 1,dealership_id: 2).latest_versions.where(state: 'WA')
			scope :live_latest_versions, -> {
				live_current_versions(nil)
			}

	    # Scopes to the current version for all iids at the given timestamp
	    # This and other methods beginning with "live" do not use the ver_current column
	    # if the timestamp is nil, it will return the highest available version regardless of current_from
			scope :live_current_versions, ->(aTimestamp) {
				aTimestamp = aTimestamp.to_ms if aTimestamp && aTimestamp.is_a?(Time)
				inner = clone.select("iid, max(version) as version")
				inner = inner.where(["current_from <= ?",aTimestamp]) if aTimestamp
				inner = inner.group(:iid).to_sql
				ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.iid = v.iid and t.version = v.version").to_a
				if (adapter = ActiveRecord::Base.configurations[Rails.env]['adapter'])=='postgresql'
					ids = ids.map{|i| i['id']}.join(',')
				elsif adapter.begins_with? 'mysql'
					ids = ids.flatten.join(',')
				else
					raise "Adapter #{adapter} not supported"
				end
				if ids.to_nil
					where "id IN (#{ids})"
				else
					where("1=0")              # relation that matches nothing
				end
			}

	    # Scopes to the current version of a given iid. Can only return 0 or 1 records
	    # This and other methods beginning with "live" do not use the ver_current column
	    scope :live_current_version, ->(aIid,aTimestamp=nil) {
		    aTimestamp ||= KojacUtils.timestamp
		    where(iid: aIid).where(["current_from <= ?",aTimestamp]).order('version DESC').limit(1)
	    }

	    # Scopes to current version for all iids using the ver_current column. The ver_current must be updated regularly using update_all_ver_current.
	    # This method is much faster than live_current_versions
	    scope :current_versions, -> {
		    where(ver_current: true)
	    }

	    # Updates the ver_current column, which enables simpler and much faster queries on current versions eg. using current_versions instead of live_current_versions.
	    # Must be run periodically eg. 4am daily
	    # !!! probably should do something like this after every create_version!
	    def self.update_all_ver_current
		    self.update_all(ver_current: false)
		    self.live_current_versions(Time.now.to_ms).update_all(ver_current: true)
	    end
    end
  end

	def copyable_attributes
		result = {}
		self.class.columns.each do |c|
			next if ['id', 'version'].include? c.name
			result[c.name.to_sym] = self.send(c.name)
		end
		result
	end

	def new_version(aValues)
		raise "iid must be set before calling new_version" unless self.iid
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.iid)
		ver = self.class.new(attrs)
		ver
	end

	def create_version!(aValues)
		raise "iid must be set before calling new_version" unless self.iid
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.iid)
		attrs.merge!(aValues.symbolize_keys)
		self.class.create!(attrs)
	end

	def current_version
		self.class.live_current_version(self.iid,KojacUtils.timestamp).first
	end

	def versions
		self.class.where(iid: iid).order(:version)
	end
end