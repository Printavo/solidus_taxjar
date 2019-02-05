module SuperGood
  module SolidusTaxJar
    class TaxCalculator
      def self.default_api
        ::SuperGood::SolidusTaxJar::API.new
      end

      def initialize(order, api: self.class.default_api)
        @order = order
        @api = api
      end

      def calculate
        return no_tax if SuperGood::SolidusTaxJar.test_mode
        return no_tax if order.tax_address.empty? || order.line_items.none?
        return no_tax unless taxable_address? order.tax_address

        cache do
          next no_tax unless taxjar_breakdown

          Spree::Tax::OrderTax.new(
            order_id: order.id,
            line_item_taxes: line_item_taxes,
            shipment_taxes: shipment_taxes
          )
        end
      rescue StandardError => e
        exception_handler.(e)
        no_tax
      end

      private

      attr_reader :order, :api

      def line_item_taxes
        @line_item_taxes ||=
          taxjar_breakdown.line_items.map do |line_item|
            Spree::Tax::ItemTax.new(
              item_id: line_item.id.to_i,
              label: "Sales Tax",
              tax_rate: tax_rate,
              amount: line_item.tax_collectable,
              included_in_price: false
            )
          end
      end

      def shipment_taxes
        @shipment_taxes ||=
          if taxjar_breakdown.shipping? &&
            (total_shipping_tax = taxjar_breakdown.shipping.tax_collectable) != 0

            # Distribute shipping tax across shipments:
            # TaxJar does not provide a breakdown of shipping taxes, so we have
            # to proportionally distribute the tax across the shipments,
            # accounting for rounding errors.
            tax_items = []
            remaining_tax = total_shipping_tax
            shipments = order.shipments.to_a
            total_shipping_cost = shipments.sum(&:total_before_tax)

            shipments[0...-1].each do |shipment|
              percentage_of_tax = shipment.total_before_tax / total_shipping_cost
              shipping_tax = (percentage_of_tax * total_shipping_tax).round(2)
              remaining_tax -= shipping_tax

              tax_items << ::Spree::Tax::ItemTax.new(
                item_id: shipment.id,
                label: shipping_tax_label(shipment, shipping_tax),
                tax_rate: tax_rate,
                amount: shipping_tax,
                included_in_price: false
              )
            end

            tax_items << ::Spree::Tax::ItemTax.new(
              item_id: shipments.last.id,
              label: shipping_tax_label(shipments.last, remaining_tax),
              tax_rate: tax_rate,
              amount: remaining_tax,
              included_in_price: false
            )

            tax_items
          else
            []
          end
      end

      def taxjar_breakdown
        @taxjar_breakdown ||= taxjar_tax.breakdown
      end

      def taxjar_tax
        @taxjar_taxes ||= api.tax_for(order)
      end

      def no_tax
        Spree::Tax::OrderTax.new(
          order_id: order.id,
          line_item_taxes: [],
          shipment_taxes: []
        )
      end

      def tax_rate
        Spree::TaxRate.find_by(name: "Sales Tax")
      end

      def cache
        if !Rails.env.test?
          Rails.cache.fetch(cache_key, expires_in: 10.minutes) { yield }
        else
          yield
        end
      end

      def cache_key
        APIParams.order_params(order).transform_values do |value|
          case value
          when Array, Hash then value.hash
          else
            value
          end
        end
      end

      def exception_handler
        SuperGood::SolidusTaxJar.exception_handler
      end

      def taxable_address?(address)
        SuperGood::SolidusTaxJar.taxable_address_check.(address)
      end

      def shipping_tax_label(shipment, shipping_tax)
        SuperGood::SolidusTaxJar.shipping_tax_label_maker.(
          shipment,
          shipping_tax
        )
      end
    end
  end
end
