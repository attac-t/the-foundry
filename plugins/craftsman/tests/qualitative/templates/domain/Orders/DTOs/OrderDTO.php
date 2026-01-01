<?php

declare(strict_types=1);

namespace Domain\Orders\DTOs;

use Carbon\Carbon;
use Domain\Orders\Models\Order;
use Domain\Products\DTOs\ProductDTO;
use Domain\Users\DTOs\UserDTO;
use Illuminate\Support\Collection;
use Spatie\LaravelData\Attributes\AutoWhenLoadedLazy;
use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Lazy;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;

#[MapName(SnakeCaseMapper::class)]
class OrderDTO extends Data
{
    public function __construct(
        public readonly int $id,
        public readonly string $status,
        public readonly string $total,
        public readonly ?string $notes,

        public readonly ?Carbon $startsAt,
        public readonly ?Carbon $endsAt,

        public readonly Carbon $createdAt,
        public readonly Carbon $updatedAt,

        /**
         * @var UserDTO|Lazy
         */
        #[AutoWhenLoadedLazy]
        public readonly UserDTO|Lazy $user,

        /**
         * @var Collection<int, ProductDTO>|Lazy
         */
        #[AutoWhenLoadedLazy]
        public readonly Collection|Lazy $products,
    ) {}

    public static function fromModel(Order $order): self
    {
        return new self(
            id: $order->getKey(),
            status: $order->status,
            total: $order->total,
            notes: $order->notes,
            startsAt: $order->starts_at,
            endsAt: $order->ends_at,
            createdAt: $order->created_at,
            updatedAt: $order->updated_at,
            user: Lazy::create(fn () => UserDTO::from($order->user)),
            products: Lazy::create(fn () => $order->products->map(fn ($p) => ProductDTO::from($p))),
        );
    }

    public function withStatus(string $status): self
    {
        return $this->with(status: $status);
    }
}
