<?php

use HelloWorld\App\Http\Controllers\HelloWorldController;
use Illuminate\Support\Facades\Route;

Route::group([
    'prefix' => 'hello-world',
    'middleware' => [],
], function () {
    Route::get('/', [HelloWorldController::class, 'handle']);
    Route::get('/debug', function () {
        return [
            'worker_id' => getmypid(),
            'memory' => memory_get_usage(true),
        ];
    });
});
