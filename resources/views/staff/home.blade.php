@extends('layouts.app')

@section('content')

<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header"> {{ trans('home.dashboard') }}</div>

                <div class="card-body">
                    @if (session('status'))
                        <div class="alert alert-success" role="alert">
                            {{ session('status') }}
                        </div>
                    @endif

                    <div class="row">
                        <div class="col">
                            <div style="text-align: center;">
                                <a class="nav-link" style="color: black" href="{{ route('staff/administrators/index') }}">
                                    <h1>
                                        <i style="font-size: 8vw" class="fas fa-users"></i>
                                    </h1>

                                    <br />

                                    {{ trans('home.administrators') }}
                                </a>
                            </div>
                        </div>

                        <div class="col" style="text-align: center;">
                            <a class="nav-link" style="color: black" href="{{ route('staff/ranks/index') }}">
                                <h1>
                                    <i style="font-size: 8vw" class="fas fa-key"></i>
                                </h1>

                                <br />
                                {{ trans('home.ranks') }}
                            </a>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col">
                            <div style="text-align: center;">
                                <a class="nav-link" style="color: black" href="">
                                    <h1>
                                        <i style="font-size: 8vw" class="fas fa-server"></i>
                                    </h1>

                                    <br />

                                    {{ trans('home.servers') }}
                                </a>
                            </div>
                        </div>

                        <div class="col">
                            <div style="text-align: center;">
                                <a class="nav-link" style="color: black" href="" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
                                    <h1>
                                        <i style="font-size: 8vw" class="fas fa-sign-out-alt"></i>
                                    </h1>

                                    <br />

                                    {{ trans('auth.logout') }}
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
