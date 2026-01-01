<?php

declare(strict_types=1);

use App\Http\Controllers\OrderController;
use Illuminate\Support\Facades\Route;

Route::apiResource('orders', OrderController::class);
