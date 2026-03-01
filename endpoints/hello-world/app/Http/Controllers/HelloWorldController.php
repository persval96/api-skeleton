<?php

namespace HelloWorld\App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class HelloWorldController
{
    public function handle(): JsonResponse
    {
        return new JsonResponse('Hello World!');
    }
}
