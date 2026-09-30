<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('external_id', 20);
            $table->timestamp('created_at')->nullable();
            $table->string('first_name', 150)->nullable();
            $table->string('last_name', 150);
            $table->string('phone', 20)->nullable();
            $table->string('email', 100)->nullable();
            $table->string('city', 100)->nullable();
            $table->string('source', 150);
            $table->string('utm_campaign', 100)->nullable();
            $table->string('product', 255);
            $table->integer('budget_uah')->nullable();
            $table->string('status', 100)->nullable();
            $table->string('manager', 100)->nullable();
            $table->text('comment')->nullable();
            $table->dateTime('next_contact_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
