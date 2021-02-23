using JuliaStream
using Test
using Statistics
using Distributions

@testset "JuliaStream.jl" begin
    # Write your tests here.
end


@testset "gaussian_estimator.jl" begin
    g = JuliaStream.GaussianEstimator()
    @test g.weight_sum == 0.0
    @test g.mean == 0.0
    @test g.variance_sum == 0.0
    test_stream_A = [1.0, 1.0, 2.0]
    for (i, value) in enumerate(test_stream_A)
        g = JuliaStream.add_weight(g, value, 1.0)
        @test g.weight_sum == i
        @test g.mean == mean(test_stream_A[1:i])
        if i > 1
            @test isapprox(JuliaStream.variance(g), var(test_stream_A[1:i]))
            @test isapprox(JuliaStream.stdev(g), std(test_stream_A[1:i]))
            @test isapprox(JuliaStream.pdf(g, 0.1), pdf(Normal(g.mean, JuliaStream.stdev(g)), 0.1))
        end
    end
    g = JuliaStream.GaussianEstimator()
    @test g.weight_sum == 0.0
    @test g.mean == 0.0
    @test g.variance_sum == 0.0
    test_stream_unweighted = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 3.0, 3.0, 4.0, 4.0, 1.0, 1.0]
    test_stream_weighted = [1.0, 1.0, 1.0, 3.0, 4.0, 1.0]
    for (i, value) in enumerate(test_stream_weighted)
        g = JuliaStream.add_weight(g, value, 2.0)
        @test g.weight_sum == i*2
        @test g.mean == mean(test_stream_unweighted[1:i*2])
        if i > 1
            @test isapprox(JuliaStream.variance(g), var(test_stream_unweighted[1:i*2]))
            @test isapprox(JuliaStream.stdev(g), std(test_stream_unweighted[1:i*2]))
            @test isapprox(JuliaStream.pdf(g, 0.1), pdf(Normal(g.mean, JuliaStream.stdev(g)), 0.1))
        end
    end
    g = JuliaStream.GaussianEstimator()
    @test g.weight_sum == 0.0
    @test g.mean == 0.0
    @test g.variance_sum == 0.0
    test_stream_neg = [-1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 3.0, 3.0, -4.0, 4.0, -1.0, 1.0]
    for (i, value) in enumerate(test_stream_neg)
        g = JuliaStream.add_weight(g, value, 1.0)
        @test g.weight_sum == i
        @test isapprox(g.mean, mean(test_stream_neg[1:i]))
        if i > 1
            @test isapprox(JuliaStream.variance(g), var(test_stream_neg[1:i]))
            @test isapprox(JuliaStream.stdev(g), std(test_stream_neg[1:i]))
            @test isapprox(JuliaStream.pdf(g, 0.1), pdf(Normal(g.mean, JuliaStream.stdev(g)), 0.1))
        end
    end

end

@testset "naive_bayes.jl" begin
    @test JuliaStream.argmax_votes(Dict(1=>0.9, 0=>0.1)) == 1
    @test JuliaStream.argmax_votes(Dict(1=>0.5, 0=>0.1, 2=>0.4)) == 1
    @test JuliaStream.argmax_votes(Dict(0=>0.5, 1=>0.1, 2=>0.4)) == 0
    @test JuliaStream.argmax_votes(Dict(0=>-0.5, 1=>0.1, 2=>0.4)) == 2

    c = JuliaStream.NaiveBayes()
    JuliaStream.partial_fit!(c, [0.5, 0.1], 0)
    @test c.observed_class_distribution[0] == 1
    @test collect(keys(c.observed_class_distribution)) == [0]
    attr1_estimator = c.attribute_observers[1].distribution_per_class[0]
    @test typeof(attr1_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr1_estimator.weight_sum, 1.0)
    @test isapprox(attr1_estimator.mean, 0.5)
    @test isapprox(attr1_estimator.variance_sum, 0.0)
    attr2_estimator = c.attribute_observers[2].distribution_per_class[0]
    @test typeof(attr2_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr2_estimator.weight_sum, 1.0)
    @test isapprox(attr2_estimator.mean, 0.1)
    @test isapprox(attr2_estimator.variance_sum, 0.0)

    JuliaStream.partial_fit!(c, [1.0, 0.0], 0)
    @test c.observed_class_distribution[0] == 2
    @test collect(keys(c.observed_class_distribution)) == [0]
    attr1_estimator = c.attribute_observers[1].distribution_per_class[0]
    @test typeof(attr1_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr1_estimator.weight_sum, 2.0)
    @test isapprox(attr1_estimator.mean, 0.75)
    @test isapprox(attr1_estimator.variance_sum, 0.125)
    attr2_estimator = c.attribute_observers[2].distribution_per_class[0]
    @test typeof(attr2_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr2_estimator.weight_sum, 2.0)
    @test isapprox(attr2_estimator.mean, 0.05)
    @test isapprox(attr2_estimator.variance_sum, 0.005)

    JuliaStream.partial_fit!(c, [1.0, 0.0], 1)
    @test c.observed_class_distribution[0] == 2
    @test c.observed_class_distribution[1] == 1
    @test collect(keys(c.observed_class_distribution)) == [0, 1]
    attr1_estimator = c.attribute_observers[1].distribution_per_class[0]
    @test typeof(attr1_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr1_estimator.weight_sum, 2.0)
    @test isapprox(attr1_estimator.mean, 0.75)
    @test isapprox(attr1_estimator.variance_sum, 0.125)
    attr2_estimator = c.attribute_observers[2].distribution_per_class[0]
    @test typeof(attr2_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr2_estimator.weight_sum, 2.0)
    @test isapprox(attr2_estimator.mean, 0.05)
    @test isapprox(attr2_estimator.variance_sum, 0.005)
    attr1_estimator = c.attribute_observers[1].distribution_per_class[1]
    @test typeof(attr1_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr1_estimator.weight_sum, 1.0)
    @test isapprox(attr1_estimator.mean, 1.0)
    @test isapprox(attr1_estimator.variance_sum, 0.0)
    attr2_estimator = c.attribute_observers[2].distribution_per_class[1]
    @test typeof(attr2_estimator) == JuliaStream.GaussianEstimator
    @test isapprox(attr2_estimator.weight_sum, 1.0)
    @test isapprox(attr2_estimator.mean, 0.0)
    @test isapprox(attr2_estimator.variance_sum, 0.0)

    c = JuliaStream.NaiveBayes()
    JuliaStream.partial_fit!(c, [0.5, 0.1], 0)
    @test JuliaStream.predict_proba(c, [0.5, 0.1]) == Dict(0=>1)
    @test JuliaStream.predict(c, [0.5, 0.1]) == 0
    JuliaStream.partial_fit!(c, [1.0, 0.0], 0)
    @test JuliaStream.predict_proba(c, [0.5, 0.1]) == Dict(0=>3.8612941052021554)
    @test JuliaStream.predict(c, [0.5, 0.1]) == 0
    JuliaStream.partial_fit!(c, [0.1, 1.0], 1)
    @test JuliaStream.predict_proba(c, [0.5, 0.1]) == Dict(0=>2.57419607013477,1=>0.0)
    @test JuliaStream.predict(c, [0.5, 0.1]) == 0
    @test JuliaStream.predict_proba(c, [0.1, 1.0]) == Dict(0=>4.9975160518252554e-40,1=>0.3333333333333333)
    @test JuliaStream.predict(c, [0.1, 1.0]) == 1
end

@testset "data\\random_tree_generator.kl" begin
    @test JuliaStream.get_cat_value_from_onehot([0, 0, 1], 1, 0, 3) == 3
    @test JuliaStream.get_cat_value_from_onehot([0, 0, 1], 1, 0, 3) == 3
    @test JuliaStream.get_cat_value_from_onehot([0, 1, 0], 1, 0, 3) == 2
    @test JuliaStream.get_cat_value_from_onehot([1, 0, 0], 1, 0, 3) == 1
    @test JuliaStream.get_cat_value_from_onehot([1, 0, 0, 0, 0, 1], 2, 0, 3) == 3
    @test JuliaStream.get_cat_value_from_onehot([1, 0, 0, 0, 1, 0], 2, 0, 3) == 2
    @test JuliaStream.get_cat_value_from_onehot([1, 0, 0, 1, 0, 0], 2, 0, 3) == 1
    @test JuliaStream.get_cat_value_from_onehot([3, 1, 0, 0, 0, 0, 1], 3, 1, 3) == 3
    @test JuliaStream.get_cat_value_from_onehot([3, 1, 0, 0, 0, 1, 0], 3, 1, 3) == 2
    @test JuliaStream.get_cat_value_from_onehot([3, 1, 0, 0, 1, 0, 0], 3, 1, 3) == 1
end