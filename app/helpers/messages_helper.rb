module MessagesHelper
  def mark_read(receipts)
    "KSAjax.ajax({url: '#{mark_read_receipts_path(:receipts => receipts)}', method: 'put'});"
  end
end
