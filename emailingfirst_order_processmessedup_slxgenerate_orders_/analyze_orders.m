function analyze_orders(orders,inventory)
num_orders=length(orders);
fulfillment=[orders(:).fulfilled];

delivered_orders=find(fulfillment==1);
order_quantity=[orders(delivered_orders).quantity];
delivery_quantity=[orders(delivered_orders).delivery_quantity];
delivery_date=[orders(delivered_orders).delivery_date];
due_date=[orders(delivered_orders).due_date];
ontime_orders=find(due_date - delivery_date > 0 );
partial_orders=find(order_quantity-delivery_quantity>0);

fprintf('\n\n******* REPORT *******\n')
disp(['No. of orders: ' num2str(num_orders)]);
disp(['Av. order size: ' num2str(mean(order_quantity))]);

fprintf('\n')
disp(['Total demand vol: ' num2str(sum(order_quantity))]);
disp(['Total demand vol fulfilled: ' num2str(sum(delivery_quantity))]);
disp(['% vol fulfilled: ' num2str(100 * sum(delivery_quantity) / sum(order_quantity)) '%']);

fprintf('\n')
disp(['No. of unfulfilled orders: ' num2str(num_orders - length(fulfillment))]);
disp(['No. of partial fulfilled orders: ' num2str(length(partial_orders))]);
disp(['Av. inventory: ' num2str(mean(inventory))]);
%figure;bar(inventory);title('Inventory');
disp(['Total shortfall :' num2str(sum(order_quantity(partial_orders)) ...
    -sum(delivery_quantity(partial_orders)))]);
disp(['Av. shortfall: ' num2str(mean(order_quantity(partial_orders)...
    -delivery_quantity(partial_orders)))]);
disp(['Av. % shortfall: ' num2str(100 * mean((order_quantity(partial_orders) ... 
    -delivery_quantity(partial_orders))./order_quantity(partial_orders))) '%']);

fprintf('\n')
disp(['Late orders: ' num2str(num_orders - length(ontime_orders))]);
disp(['Av. no of days delivered in advance: ' ...
    num2str(mean(due_date(ontime_orders)-delivery_date(ontime_orders))) ]);
