<?php

namespace HelloWorld\Tests;

use Illuminate\Foundation\Testing\TestCase;

class HelloWorldTest extends TestCase
{
    public const string ROUTE = '/hello-world';

    public function test_get_hello_world_should_be_ok(): void
    {
        $response = $this->get(self::ROUTE);
        $response->assertStatus(200);
        $response->assertHeader('Content-Type', 'application/json');
        $response->assertExactJson(['Hello World!']);
    }
}
