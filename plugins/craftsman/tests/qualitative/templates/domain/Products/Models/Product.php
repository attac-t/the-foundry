<?php

declare(strict_types=1);

namespace Domain\Products\Models;

use Domain\Products\DTOs\ProductDTO;
use Illuminate\Database\Eloquent\Model;
use Spatie\LaravelData\WithData;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class Product extends Model implements HasMedia
{
    use InteractsWithMedia, WithData;

    protected string $dataClass = ProductDTO::class;

    protected $fillable = [
        'name',
        'sku',
        'price',
        'description',
    ];

    protected $casts = [
        'price' => 'decimal:2',
    ];

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('images');

        $this->addMediaCollection('thumbnail')
            ->singleFile();
    }
}
