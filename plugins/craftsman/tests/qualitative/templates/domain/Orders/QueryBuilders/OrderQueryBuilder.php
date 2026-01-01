<?php

declare(strict_types=1);

namespace Domain\Orders\QueryBuilders;

use Illuminate\Database\Eloquent\Builder;

/**
 * @template TModel of \Domain\Orders\Models\Order
 *
 * @extends Builder<TModel>
 */
class OrderQueryBuilder extends Builder
{
    public function forUser(int $userId): static
    {
        return $this->where('user_id', $userId);
    }

    public function withStatus(string $status): static
    {
        return $this->where('status', $status);
    }

    public function pending(): static
    {
        return $this->withStatus('pending');
    }

    public function completed(): static
    {
        return $this->withStatus('completed');
    }
}
