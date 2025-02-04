class Account::DataEnricher
  include Providable

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def run
    total_unenriched = account.entries.account_transactions
      .where("enriched_at IS NULL OR merchant_id IS NULL OR category_id IS NULL")
      .count

    if total_unenriched > 0
      batch_size = 50
      batches = (total_unenriched.to_f / batch_size).ceil

      batches.times do |batch|
        EnrichTransactionBatchJob.perform_later(account, batch_size, batch * batch_size)
      end
    end
  end

  def enrich_transaction_batch(batch_size = 50, offset = 0)
    candidates = account.entries.account_transactions
      .includes(entryable: [ :merchant, :category ])
      .where("enriched_at IS NULL OR merchant_id IS NULL OR category_id IS NULL")
      .offset(offset)
      .limit(batch_size)

    Rails.logger.info("Enriching batch of #{candidates.count} transactions for account #{account.id} (offset: #{offset})")

    merchants = {}

    candidates.each do |entry|
      begin
        next unless entry.name.present?

        info = self.class.synth_provider.enrich_transaction(entry.name).info

        next unless info.present?

        if info.name.present?
          merchant = merchants[info.name] ||= account.family.merchants.find_or_create_by(name: info.name)

          if info.icon_url.present?
            merchant.icon_url = info.icon_url
          end
        end

        entryable_attributes = { id: entry.entryable_id }
        entryable_attributes[:merchant_id] = merchant.id if merchant.present? && entry.entryable.merchant_id.nil?

        Account.transaction do
          merchant.save! if merchant.present?
          entry.update!(
            enriched_at: Time.current,
            enriched_name: info.name,
            entryable_attributes: entryable_attributes
          )
        end
      rescue => e
        Rails.logger.warn("Error enriching transaction #{entry.id}: #{e.message}")
      end
    end
  end
end
