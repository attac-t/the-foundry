<?php

declare(strict_types=1);

namespace Domain\Products\DTOs;

use Carbon\Carbon;
use Domain\Products\Models\Product;
use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;

#[MapName(SnakeCaseMapper::class)]
class ProductDTO extends Data
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
        public readonly string $sku,
        public readonly string $price,
        public readonly ?string $thumbnailUrl,
        public readonly Carbon $createdAt,
        public readonly Carbon $updatedAt,
    ) {}

    public static function fromModel(Product $product): self
    {
        return new self(
            id: $product->getKey(),
            name: $product->name,
            sku: $product->sku,
            price: $product->price,
            thumbnailUrl: $product->getFirstMediaUrl('thumbnail'),
            createdAt: $product->created_at,
            updatedAt: $product->updated_at,
        );
    }
}
