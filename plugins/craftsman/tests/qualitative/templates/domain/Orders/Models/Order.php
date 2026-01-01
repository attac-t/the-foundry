<?php

declare(strict_types=1);

namespace Domain\Orders\Models;

use Domain\Orders\DTOs\OrderDTO;
use Domain\Orders\QueryBuilders\OrderQueryBuilder;
use Domain\Products\Models\Product;
use Domain\Users\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Query\Builder;
use Spatie\LaravelData\WithData;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

/**
 * @method static OrderQueryBuilder query()
 */
class Order extends Model implements HasMedia
{
    use InteractsWithMedia, WithData;

    protected string $dataClass = OrderDTO::class;

    protected $fillable = [
        'user_id',
        'status',
        'total',
        'notes',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'total' => 'decimal:2',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    /**
     * @param  Builder  $query
     * @return OrderQueryBuilder<static>
     */
    public function newEloquentBuilder($query): OrderQueryBuilder
    {
        /** @var OrderQueryBuilder<static> */
        return new OrderQueryBuilder($query);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class)
            ->withPivot(['quantity', 'price'])
            ->withTimestamps();
    }

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('receipts')
            ->singleFile();

        $this->addMediaCollection('attachments');
    }
}
