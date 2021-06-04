<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Administrator extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'auth',
        'password',
        'account_flags',
        'rank_id',
        'expiration',
    ];

    /**
     * Get the rank associated with the administrator.
     */
    public function rank()
    {
        return $this->belongsTo(Rank::class);
    }

    /**
     * Get the privileges for the administrator.
     */
    public function privileges()
    {
        return $this->hasMany(Privilege::class);
    }
}
