# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user

  def initialize(user, scope = nil)
    @user = user
    @scope = scope || base_scope
  end

  def base_scope
    ApplicationRecord.none
  end

  def index?
    false
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def resolve
    scope
  end

  def authorize!(action, message = nil)
    raise NotAuthorizedError.new(message) unless public_send(action)
  end

  private

    attr_reader :scope
end
