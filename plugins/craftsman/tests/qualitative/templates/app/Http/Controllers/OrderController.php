<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Domain\Orders\Actions\CreateOrderAction;
use Domain\Orders\Actions\DeleteOrderAction;
use Domain\Orders\Actions\UpdateOrderAction;
use Domain\Orders\DTOs\OrderDTO;
use Domain\Orders\DTOs\UpsertOrderDTO;
use Domain\Orders\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function __construct(
        protected readonly CreateOrderAction $createOrder,
        protected readonly UpdateOrderAction $updateOrder,
        protected readonly DeleteOrderAction $deleteOrder,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $orders = Order::query()
            ->with(['user', 'products'])
            ->latest()
            ->paginate();

        return response()->json(OrderDTO::collect($orders));
    }

    public function store(UpsertOrderDTO $dto): JsonResponse
    {
        $order = DB::transaction(fn () => $this->createOrder->execute(dto: $dto));

        return response()->json($order->getData(), 201);
    }

    public function show(Order $order): JsonResponse
    {
        $order->load(['user', 'products', 'media']);

        return response()->json($order->getData());
    }

    public function update(Order $order, UpsertOrderDTO $dto): JsonResponse
    {
        $updated = DB::transaction(fn () => $this->updateOrder->execute(order: $order, dto: $dto));

        return response()->json($updated->getData());
    }

    public function destroy(Order $order): JsonResponse
    {
        DB::transaction(fn () => $this->deleteOrder->execute(order: $order));

        return response()->json(null, 204);
    }
}
