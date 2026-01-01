<?php

declare(strict_types=1);

namespace Domain\Users\DTOs;

use Carbon\Carbon;
use Domain\Users\Models\User;
use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;

#[MapName(SnakeCaseMapper::class)]
class UserDTO extends Data
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
        public readonly string $email,
        public readonly ?string $avatarUrl,
        public readonly Carbon $createdAt,
        public readonly Carbon $updatedAt,
    ) {}

    public static function fromModel(User $user): self
    {
        return new self(
            id: $user->getKey(),
            name: $user->name,
            email: $user->email,
            avatarUrl: $user->getFirstMediaUrl('avatar'),
            createdAt: $user->created_at,
            updatedAt: $user->updated_at,
        );
    }
}
