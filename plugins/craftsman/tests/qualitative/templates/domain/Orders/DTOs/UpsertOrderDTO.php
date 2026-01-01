<?php

declare(strict_types=1);

namespace Domain\Orders\DTOs;

use Carbon\Carbon;
use Spatie\LaravelData\Attributes\FromRouteParameterProperty;
use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Attributes\Validation\Exists;
use Spatie\LaravelData\Attributes\Validation\Min;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;
use Spatie\LaravelData\Optional;

#[MapName(SnakeCaseMapper::class)]
class UpsertOrderDTO extends Data
{
    public function __construct(
        #[FromRouteParameterProperty('order', 'id')]
        public readonly int|Optional $id,

        #[Exists('users', 'id')]
        public readonly int $userId,

        /** @var array<int, array{product_id: int, quantity: int}> */
        #[Min(1)]
        public readonly array $items,

        public readonly ?string $notes = null,

        public readonly ?Carbon $startsAt = null,

        public readonly ?Carbon $endsAt = null,
    ) {}
}
