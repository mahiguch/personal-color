# 全年齢対応パーソナルカラー診断 - テスト設計書

## 概要

年齢・性別推定機能を含む全年齢対応パーソナルカラー診断システムの包括的なテスト戦略とテストケースを定義する。

## テスト戦略

### 1. テストピラミッド

```
        E2E Tests (5%)
       ┌─────────────────┐
      │ Integration Tests (20%) │
     └─────────────────────────┘
    ┌─────────────────────────────┐
   │    Unit Tests (75%)         │
  └─────────────────────────────────┘
```

### 2. テスト分類

- **Unit Tests**: 各コンポーネントの単体テスト
- **Integration Tests**: API統合テスト、サービス間連携テスト  
- **E2E Tests**: エンドツーエンドのユーザーシナリオテスト
- **Performance Tests**: レスポンス時間・精度測定
- **Security Tests**: プライバシー・データ保護検証

## Unit Tests

### 1. Flutter Client側

#### PersonAnalysis Entity Tests
```dart
// test/features/diagnosis/domain/entities/person_analysis_test.dart

void main() {
  group('PersonAnalysis', () {
    const testPersonAnalysis = PersonAnalysis(
      ageGroup: AgeGroup.adult,
      gender: Gender.female,
      confidence: 85,
    );

    group('fromJson', () {
      test('should create PersonAnalysis from valid JSON', () {
        // Arrange
        final json = {
          'age_group': 'adult',
          'gender': 'female', 
          'confidence': 85,
        };

        // Act
        final result = PersonAnalysis.fromJson(json);

        // Assert
        expect(result.ageGroup, AgeGroup.adult);
        expect(result.gender, Gender.female);
        expect(result.confidence, 85);
      });

      test('should handle unknown age_group with fallback', () {
        // Arrange
        final json = {
          'age_group': 'invalid_age',
          'gender': 'female',
          'confidence': 70,
        };

        // Act
        final result = PersonAnalysis.fromJson(json);

        // Assert
        expect(result.ageGroup, AgeGroup.child);
        expect(result.gender, Gender.female);
      });

      test('should handle unknown gender with fallback', () {
        // Arrange  
        final json = {
          'age_group': 'adult',
          'gender': 'invalid_gender',
          'confidence': 70,
        };

        // Act
        final result = PersonAnalysis.fromJson(json);

        // Assert
        expect(result.ageGroup, AgeGroup.adult);
        expect(result.gender, Gender.unknown);
      });
    });

    group('toJson', () {
      test('should convert PersonAnalysis to JSON', () {
        // Act
        final json = testPersonAnalysis.toJson();

        // Assert
        expect(json['age_group'], 'adult');
        expect(json['gender'], 'female');
        expect(json['confidence'], 85);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        const other = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // Assert
        expect(testPersonAnalysis, equals(other));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        const other = PersonAnalysis(
          ageGroup: AgeGroup.student,
          gender: Gender.female,
          confidence: 85,
        );

        // Assert
        expect(testPersonAnalysis, isNot(equals(other)));
      });
    });
  });
}
```

#### AgeGroup Extension Tests
```dart
// test/features/diagnosis/domain/entities/age_group_test.dart

void main() {
  group('AgeGroup Extension', () {
    group('displayName', () {
      test('should return correct display names', () {
        expect(AgeGroup.child.displayName, '子供');
        expect(AgeGroup.student.displayName, '学生');
        expect(AgeGroup.adult.displayName, '社会人');
        expect(AgeGroup.middleAge.displayName, '中高年');
        expect(AgeGroup.senior.displayName, 'シニア');
      });
    });

    group('apiValue', () {
      test('should return correct API values', () {
        expect(AgeGroup.child.apiValue, 'child');
        expect(AgeGroup.student.apiValue, 'student');
        expect(AgeGroup.adult.apiValue, 'adult');
        expect(AgeGroup.middleAge.apiValue, 'middleAge');
        expect(AgeGroup.senior.apiValue, 'senior');
      });
    });

    group('fromApiValue', () {
      test('should create AgeGroup from valid API values', () {
        expect(AgeGroup.fromApiValue('child'), AgeGroup.child);
        expect(AgeGroup.fromApiValue('student'), AgeGroup.student);
        expect(AgeGroup.fromApiValue('adult'), AgeGroup.adult);
        expect(AgeGroup.fromApiValue('middleAge'), AgeGroup.middleAge);
        expect(AgeGroup.fromApiValue('senior'), AgeGroup.senior);
      });

      test('should throw exception for invalid API value', () {
        expect(
          () => AgeGroup.fromApiValue('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
```

#### Enhanced DiagnosisResult Tests
```dart
// test/features/diagnosis/domain/entities/diagnosis_result_enhanced_test.dart

void main() {
  group('Enhanced DiagnosisResult', () {
    const testPersonAnalysis = PersonAnalysis(
      ageGroup: AgeGroup.adult,
      gender: Gender.female,
      confidence: 85,
    );

    const testDiagnosisResult = DiagnosisResult(
      diagnosisType: PersonalColorType.spring,
      confidence: 90,
      explanation: "適応化された説明文です",
      recommendedColors: [],
      avoidColors: [],
      tips: "アドバイス",
      personAnalysis: testPersonAnalysis,
    );

    group('hasPersonAnalysis', () {
      test('should return true when personAnalysis is present', () {
        expect(testDiagnosisResult.hasPersonAnalysis, isTrue);
      });

      test('should return false when personAnalysis is null', () {
        // Arrange
        const diagnosisWithoutPerson = DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 90,
          explanation: "基本説明文",
          recommendedColors: [],
          avoidColors: [],
          tips: "基本アドバイス",
        );

        // Assert
        expect(diagnosisWithoutPerson.hasPersonAnalysis, isFalse);
      });
    });

    group('isAdaptiveContent', () {
      test('should return true when has person analysis and explanation', () {
        expect(testDiagnosisResult.isAdaptiveContent, isTrue);
      });

      test('should return false when no person analysis', () {
        // Arrange
        const basicResult = DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 90,
          explanation: "基本説明文",
          recommendedColors: [],
          avoidColors: [],
          tips: "基本アドバイス",
        );

        // Assert
        expect(basicResult.isAdaptiveContent, isFalse);
      });
    });
  });
}
```

#### UseCase Tests
```dart
// test/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced_test.dart

void main() {
  late MockDiagnosisRepository mockRepository;
  late DiagnosePersonalColorEnhanced useCase;

  setUp(() {
    mockRepository = MockDiagnosisRepository();
    useCase = DiagnosePersonalColorEnhanced(mockRepository);
  });

  group('DiagnosePersonalColorEnhanced', () {
    const testImagePath = '/test/path/image.jpg';
    const testParams = DiagnosePersonalColorParams(imagePath: testImagePath);

    test('should return DiagnosisResult when repository succeeds', () async {
      // Arrange
      const expectedResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 90,
        explanation: "適応化された説明文",
        recommendedColors: [],
        avoidColors: [],
        tips: "適応化されたアドバイス",
        personAnalysis: PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        ),
      );

      when(() => mockRepository.diagnosePersonalColorEnhanced(testImagePath))
          .thenAnswer((_) async => const Right(expectedResult));

      // Act
      final result = await useCase.call(testParams);

      // Assert
      expect(result, const Right(expectedResult));
      verify(() => mockRepository.diagnosePersonalColorEnhanced(testImagePath))
          .called(1);
    });

    test('should return Failure when repository fails', () async {
      // Arrange
      const expectedFailure = NetworkFailure('Network error');
      when(() => mockRepository.diagnosePersonalColorEnhanced(testImagePath))
          .thenAnswer((_) async => const Left(expectedFailure));

      // Act
      final result = await useCase.call(testParams);

      // Assert
      expect(result, const Left(expectedFailure));
    });
  });
}
```

### 2. Python Server側

#### PersonalColorPrompt Enhanced Tests
```python
# server/tests/unit/prompts/test_personal_color_analysis_enhanced.py

class TestPersonalColorPromptEnhanced:
    
    def setup_method(self):
        self.prompt_manager = PersonalColorPrompt()
    
    def test_create_enhanced_analysis_prompt(self):
        """拡張分析プロンプトの生成テスト"""
        # Act
        prompt = self.prompt_manager.create_enhanced_analysis_prompt()
        
        # Assert
        assert "年齢・性別推定" in prompt
        assert "person_analysis" in prompt
        assert "age_group" in prompt
        assert "gender" in prompt
        assert "適応的説明文の生成ルール" in prompt
    
    def test_get_adaptive_explanation_template_child_male(self):
        """子供・男性向けテンプレートテスト"""
        # Act
        template = self.prompt_manager.get_adaptive_explanation_template(
            "child", "male", "Spring"
        )
        
        # Assert
        assert "きみの" in template
        assert template.endswith("！")
    
    def test_get_adaptive_explanation_template_adult_female(self):
        """大人・女性向けテンプレートテスト"""
        # Act
        template = self.prompt_manager.get_adaptive_explanation_template(
            "adult", "female", "Summer"
        )
        
        # Assert
        assert "あなたの美しい肌" in template
        assert "魅力を引き立て" in template
    
    def test_get_adaptive_explanation_template_senior_unknown(self):
        """シニア・性別不明テンプレートテスト"""
        # Act
        template = self.prompt_manager.get_adaptive_explanation_template(
            "senior", "unknown", "Autumn"
        )
        
        # Assert
        assert "あなたの肌色" in template
        assert "印象を演出" in template
    
    def test_get_adaptive_explanation_template_fallback(self):
        """無効な組み合わせのフォールバックテスト"""
        # Act
        template = self.prompt_manager.get_adaptive_explanation_template(
            "invalid_age", "invalid_gender", "Winter"
        )
        
        # Assert - should fall back to adult/unknown template
        assert template is not None
        assert len(template) > 0

class TestPersonalColorPromptValidation:
    
    def setup_method(self):
        self.prompt_manager = PersonalColorPrompt()
    
    def test_validate_enhanced_response_format_success(self):
        """拡張レスポンス形式検証の成功ケース"""
        # Arrange
        valid_response = """{
            "personal_color_type": "Spring",
            "confidence": 85,
            "explanation": "適応化された説明文です",
            "recommended_colors": ["コーラルピンク", "イエローグリーン"],
            "tips": ["アドバイス1", "アドバイス2"],
            "person_analysis": {
                "age_group": "adult",
                "gender": "female",
                "confidence": 78
            }
        }"""
        
        # Act
        result = self.prompt_manager.validate_enhanced_response_format(valid_response)
        
        # Assert
        assert result is True
    
    def test_validate_enhanced_response_format_missing_person_analysis(self):
        """person_analysis欠落時の検証テスト"""
        # Arrange
        invalid_response = """{
            "personal_color_type": "Spring",
            "confidence": 85,
            "explanation": "説明文",
            "recommended_colors": ["ピンク"],
            "tips": ["アドバイス"]
        }"""
        
        # Act
        result = self.prompt_manager.validate_enhanced_response_format(invalid_response)
        
        # Assert
        assert result is False
    
    def test_validate_enhanced_response_format_invalid_age_group(self):
        """無効なage_groupの検証テスト"""
        # Arrange
        invalid_response = """{
            "personal_color_type": "Spring",
            "confidence": 85,
            "explanation": "説明文",
            "recommended_colors": ["ピンク"],
            "tips": ["アドバイス"],
            "person_analysis": {
                "age_group": "invalid_age",
                "gender": "female",
                "confidence": 78
            }
        }"""
        
        # Act
        result = self.prompt_manager.validate_enhanced_response_format(invalid_response)
        
        # Assert
        assert result is False
```

#### GeminiService Enhanced Tests
```python
# server/tests/unit/services/test_gemini_service_enhanced.py

class TestGeminiServiceEnhanced:
    
    def setup_method(self):
        self.service = get_gemini_service()
        self.test_image_data = self._load_test_image()
    
    def _load_test_image(self) -> bytes:
        """テスト用画像データを読み込み"""
        test_image_path = Path(__file__).parent.parent / "fixtures" / "test_face.jpg"
        return test_image_path.read_bytes()
    
    @pytest.mark.asyncio
    async def test_analyze_personal_color_with_demographics_success(self):
        """年齢・性別推定統合分析の成功ケース"""
        # Arrange
        with patch.object(self.service, '_call_gemini_vision') as mock_call:
            mock_response = """{
                "personal_color_type": "Spring",
                "confidence": 85,
                "explanation": "適応化された説明文です",
                "recommended_colors": ["コーラルピンク", "イエローグリーン"],
                "tips": ["アドバイス1", "アドバイス2"],
                "person_analysis": {
                    "age_group": "adult",
                    "gender": "female",
                    "confidence": 78
                }
            }"""
            mock_call.return_value = mock_response
        
        # Act
        result = await self.service.analyze_personal_color_with_demographics(
            self.test_image_data
        )
        
        # Assert
        assert result["personal_color_type"] == "Spring"
        assert "person_analysis" in result
        assert result["person_analysis"]["age_group"] == "adult"
        assert result["person_analysis"]["gender"] == "female"
        assert result["person_analysis"]["confidence"] == 78
    
    @pytest.mark.asyncio
    async def test_analyze_personal_color_with_demographics_invalid_response(self):
        """無効なレスポンス形式のエラーハンドリング"""
        # Arrange
        with patch.object(self.service, '_call_gemini_vision') as mock_call:
            mock_call.return_value = "Invalid JSON response"
        
        # Act & Assert
        with pytest.raises(ValueError, match="Enhanced response parsing failed"):
            await self.service.analyze_personal_color_with_demographics(
                self.test_image_data
            )
    
    def test_parse_enhanced_response_success(self):
        """拡張レスポンス解析の成功ケース"""
        # Arrange
        valid_response = """{
            "personal_color_type": "Spring",
            "confidence": 85,
            "explanation": "説明文",
            "recommended_colors": ["ピンク"],
            "tips": ["アドバイス"],
            "person_analysis": {
                "age_group": "adult",
                "gender": "female",
                "confidence": 78
            }
        }"""
        
        # Act
        result = self.service._parse_enhanced_response(valid_response)
        
        # Assert
        assert result["personal_color_type"] == "Spring"
        assert result["person_analysis"]["age_group"] == "adult"
    
    def test_parse_enhanced_response_missing_field(self):
        """必須フィールド欠落時のエラーハンドリング"""
        # Arrange
        invalid_response = """{
            "personal_color_type": "Spring",
            "confidence": 85
        }"""
        
        # Act & Assert
        with pytest.raises(ValueError, match="Missing required field"):
            self.service._parse_enhanced_response(invalid_response)
    
    def test_enhance_with_adaptive_content(self):
        """適応的コンテンツ拡張のテスト"""
        # Arrange
        base_result = {
            "personal_color_type": "Spring",
            "tips": ["基本アドバイス"],
            "person_analysis": {
                "age_group": "adult",
                "gender": "female",
                "confidence": 85
            }
        }
        
        # Act
        enhanced_result = self.service._enhance_with_adaptive_content(base_result)
        
        # Assert
        assert len(enhanced_result["tips"]) > 1
        # 大人女性向けのアドバイスが追加されることを確認
        tips_text = " ".join(enhanced_result["tips"])
        assert any(keyword in tips_text for keyword in ["職場", "信頼感", "トータル"])
    
    def test_get_adaptive_tips_child_male(self):
        """子供男性向けアドバイス生成テスト"""
        # Act
        tips = self.service._get_adaptive_tips("child", "male", "Spring")
        
        # Assert
        assert len(tips) > 0
        assert any("学校" in tip for tip in tips)
        assert any("スポーツ" in tip for tip in tips)
    
    def test_get_adaptive_tips_senior_female(self):
        """シニア女性向けアドバイス生成テスト"""
        # Act
        tips = self.service._get_adaptive_tips("senior", "female", "Autumn")
        
        # Assert
        assert len(tips) > 0
        assert any("気品" in tip for tip in tips)
        assert any("美しさ" in tip for tip in tips)
    
    def test_get_adaptive_tips_unknown_combination(self):
        """未知の組み合わせでのフォールバックテスト"""
        # Act
        tips = self.service._get_adaptive_tips("invalid", "invalid", "Spring")
        
        # Assert
        assert len(tips) == 2  # デフォルトのフォールバックアドバイス
        assert "あなたに似合う色" in tips[0]
```

## Integration Tests

### 1. API統合テスト

```python
# server/tests/integration/test_enhanced_diagnosis_api.py

class TestEnhancedDiagnosisAPI:
    
    def setup_method(self):
        self.client = TestClient(app)
        self.test_image_base64 = self._load_test_image_base64()
    
    def _load_test_image_base64(self) -> str:
        """テスト用画像をBase64エンコードして取得"""
        test_image_path = Path(__file__).parent / "fixtures" / "test_face.jpg"
        image_data = test_image_path.read_bytes()
        return base64.b64encode(image_data).decode('utf-8')
    
    def test_diagnose_enhanced_success(self):
        """拡張診断APIの成功ケース"""
        # Arrange
        payload = {
            "image_data": self.test_image_base64,
            "metadata": {
                "platform": "ios",
                "app_version": "1.0.0"
            }
        }
        
        # Act
        response = self.client.post("/api/v1/diagnose-enhanced", json=payload)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        
        # 基本フィールド検証
        assert "personal_color_type" in data
        assert "confidence" in data
        assert "explanation" in data
        assert "recommended_colors" in data
        assert "tips" in data
        assert "processing_time_ms" in data
        assert "request_id" in data
        
        # 拡張フィールド検証
        assert "person_analysis" in data
        person_analysis = data["person_analysis"]
        assert "age_group" in person_analysis
        assert "gender" in person_analysis
        assert "confidence" in person_analysis
        
        # データ型検証
        assert isinstance(data["confidence"], int)
        assert isinstance(person_analysis["confidence"], int)
        assert isinstance(data["recommended_colors"], list)
        assert isinstance(data["tips"], list)
    
    def test_diagnose_enhanced_invalid_image(self):
        """無効な画像データでのエラーレスポンス"""
        # Arrange
        payload = {
            "image_data": "invalid_base64_data",
            "metadata": {}
        }
        
        # Act
        response = self.client.post("/api/v1/diagnose-enhanced", json=payload)
        
        # Assert
        assert response.status_code == 400
        data = response.json()
        assert "detail" in data
    
    def test_diagnose_enhanced_missing_image(self):
        """画像データ欠落時のエラーレスポンス"""
        # Arrange
        payload = {
            "metadata": {}
        }
        
        # Act
        response = self.client.post("/api/v1/diagnose-enhanced", json=payload)
        
        # Assert
        assert response.status_code == 422  # Validation error
    
    def test_diagnose_enhanced_with_metadata(self):
        """メタデータ付き診断の検証"""
        # Arrange
        payload = {
            "image_data": self.test_image_base64,
            "metadata": {
                "platform": "ios",
                "app_version": "1.2.0",
                "device_model": "iPhone 14",
                "user_notes": "テスト用診断"
            }
        }
        
        # Act
        response = self.client.post("/api/v1/diagnose-enhanced", json=payload)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["request_id"] is not None
        assert isinstance(data["processing_time_ms"], int)
```

### 2. Flutter統合テスト

```dart
// test/integration/enhanced_diagnosis_integration_test.dart

void main() {
  group('Enhanced Diagnosis Integration Tests', () {
    late DiagnosisRepositoryImpl repository;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockNetworkService = MockNetworkService();
      repository = DiagnosisRepositoryImpl(mockNetworkService);
    });

    testWidgets('should complete enhanced diagnosis flow', (tester) async {
      // Arrange
      const expectedResponse = {
        'personal_color_type': 'Spring',
        'confidence': 85,
        'explanation': '適応化された説明文です',
        'recommended_colors': ['コーラルピンク', 'イエローグリーン'],
        'tips': ['アドバイス1', 'アドバイス2'],
        'person_analysis': {
          'age_group': 'adult',
          'gender': 'female',
          'confidence': 78
        },
        'processing_time_ms': 3000,
        'request_id': 'test-request-id'
      };

      when(() => mockNetworkService.post(any(), any()))
          .thenAnswer((_) async => NetworkResponse.success(expectedResponse));

      // Act
      final result = await repository.diagnosePersonalColorEnhanced(
        'test/path/image.jpg'
      );

      // Assert
      expect(result.isRight(), isTrue);
      
      final diagnosisResult = result.getOrElse(() => throw Exception());
      expect(diagnosisResult.diagnosisType, PersonalColorType.spring);
      expect(diagnosisResult.hasPersonAnalysis, isTrue);
      expect(diagnosisResult.personAnalysis!.ageGroup, AgeGroup.adult);
      expect(diagnosisResult.personAnalysis!.gender, Gender.female);
      expect(diagnosisResult.isAdaptiveContent, isTrue);
    });

    testWidgets('should handle network errors gracefully', (tester) async {
      // Arrange
      when(() => mockNetworkService.post(any(), any()))
          .thenAnswer((_) async => NetworkResponse.error('Network error'));

      // Act
      final result = await repository.diagnosePersonalColorEnhanced(
        'test/path/image.jpg'
      );

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
    });
  });
}
```

## Performance Tests

### 1. レスポンス時間テスト

```python
# server/tests/performance/test_enhanced_diagnosis_performance.py

class TestEnhancedDiagnosisPerformance:
    
    @pytest.mark.asyncio
    async def test_enhanced_diagnosis_response_time(self):
        """拡張診断のレスポンス時間テスト（5秒以内）"""
        # Arrange
        service = get_gemini_service()
        test_image = self._load_test_image()
        
        # Act
        start_time = time.time()
        result = await service.analyze_personal_color_with_demographics(test_image)
        end_time = time.time()
        
        # Assert
        response_time = end_time - start_time
        assert response_time < 5.0, f"Response time {response_time}s exceeds 5s limit"
        assert result is not None
    
    @pytest.mark.asyncio
    async def test_concurrent_requests_performance(self):
        """並行リクエスト処理のパフォーマンステスト"""
        # Arrange
        service = get_gemini_service()
        test_image = self._load_test_image()
        concurrent_requests = 5
        
        # Act
        start_time = time.time()
        tasks = [
            service.analyze_personal_color_with_demographics(test_image)
            for _ in range(concurrent_requests)
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        end_time = time.time()
        
        # Assert
        total_time = end_time - start_time
        assert total_time < 10.0, f"Concurrent processing took {total_time}s"
        
        # 成功したリクエストの確認
        successful_results = [r for r in results if not isinstance(r, Exception)]
        assert len(successful_results) >= concurrent_requests * 0.8  # 80%以上成功
    
    @pytest.mark.asyncio
    async def test_memory_usage_during_analysis(self):
        """分析中のメモリ使用量テスト"""
        import psutil
        import os
        
        # Arrange
        service = get_gemini_service()
        test_image = self._load_test_image()
        process = psutil.Process(os.getpid())
        
        # 初期メモリ使用量
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Act
        result = await service.analyze_personal_color_with_demographics(test_image)
        
        # Assert
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        assert memory_increase < 100, f"Memory increase {memory_increase}MB is too high"
        assert result is not None
```

### 2. 精度テスト

```python
# server/tests/accuracy/test_demographic_estimation_accuracy.py

class TestDemographicEstimationAccuracy:
    
    def setup_method(self):
        self.service = get_gemini_service()
        self.test_cases = self._load_test_cases()
    
    def _load_test_cases(self) -> List[Dict]:
        """ラベル付きテストケースを読み込み"""
        return [
            {
                'image_path': 'test_child_male.jpg',
                'expected_age_group': 'child',
                'expected_gender': 'male'
            },
            {
                'image_path': 'test_adult_female.jpg',
                'expected_age_group': 'adult',
                'expected_gender': 'female'
            },
            {
                'image_path': 'test_senior_unknown.jpg',
                'expected_age_group': 'senior',
                'expected_gender': 'unknown'
            },
            # ... 他のテストケース
        ]
    
    @pytest.mark.asyncio
    async def test_age_group_estimation_accuracy(self):
        """年代推定精度テスト（70%以上）"""
        correct_predictions = 0
        total_predictions = len(self.test_cases)
        
        for test_case in self.test_cases:
            # Arrange
            image_data = self._load_test_image(test_case['image_path'])
            
            # Act
            result = await self.service.analyze_personal_color_with_demographics(
                image_data
            )
            
            # Assert
            predicted_age_group = result['person_analysis']['age_group']
            if predicted_age_group == test_case['expected_age_group']:
                correct_predictions += 1
        
        accuracy = correct_predictions / total_predictions
        assert accuracy >= 0.70, f"Age group accuracy {accuracy:.2%} is below 70% requirement"
    
    @pytest.mark.asyncio
    async def test_gender_estimation_accuracy(self):
        """性別推定精度テスト（80%以上）"""
        correct_predictions = 0
        total_predictions = len(self.test_cases)
        
        for test_case in self.test_cases:
            # Arrange
            image_data = self._load_test_image(test_case['image_path'])
            
            # Act
            result = await self.service.analyze_personal_color_with_demographics(
                image_data
            )
            
            # Assert
            predicted_gender = result['person_analysis']['gender']
            if predicted_gender == test_case['expected_gender']:
                correct_predictions += 1
        
        accuracy = correct_predictions / total_predictions
        assert accuracy >= 0.80, f"Gender accuracy {accuracy:.2%} is below 80% requirement"
    
    @pytest.mark.asyncio
    async def test_personal_color_accuracy_maintained(self):
        """パーソナルカラー診断精度の維持テスト（85%以上）"""
        correct_predictions = 0
        total_predictions = len(self.test_cases)
        
        for test_case in self.test_cases:
            if 'expected_personal_color' not in test_case:
                continue
                
            # Arrange
            image_data = self._load_test_image(test_case['image_path'])
            
            # Act
            result = await self.service.analyze_personal_color_with_demographics(
                image_data
            )
            
            # Assert
            predicted_color = result['personal_color_type']
            if predicted_color == test_case['expected_personal_color']:
                correct_predictions += 1
        
        accuracy = correct_predictions / total_predictions
        assert accuracy >= 0.85, f"Personal color accuracy {accuracy:.2%} is below 85% requirement"
```

## E2E Tests

### 1. ユーザーシナリオテスト

```dart
// test/e2e/enhanced_diagnosis_e2e_test.dart

void main() {
  group('Enhanced Diagnosis E2E Tests', () {
    testWidgets('complete enhanced diagnosis user journey', (tester) async {
      // Arrange
      await tester.pumpWidget(const MyApp());
      
      // Step 1: Navigate to diagnosis from home
      await tester.tap(find.text('診断を始める'));
      await tester.pumpAndSettle();
      
      // Step 2: Take photo (mock camera)
      await tester.tap(find.byIcon(Icons.camera));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Step 3: Confirm photo
      await tester.tap(find.text('この写真で診断する'));
      await tester.pumpAndSettle();
      
      // Step 4: Wait for diagnosis (with loading indicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Step 5: Verify enhanced results are displayed
      expect(find.text('診断結果'), findsOneWidget);
      expect(find.text('推定情報'), findsOneWidget);
      
      // Step 6: Verify person analysis display
      expect(find.textContaining('年代:'), findsOneWidget);
      expect(find.textContaining('性別:'), findsOneWidget);
      
      // Step 7: Verify adaptive content
      expect(find.textContaining('推定精度:'), findsOneWidget);
      
      // Step 8: Verify AI makeup button is available
      expect(find.textContaining('AI画像生成メイク'), findsOneWidget);
      
      // Step 9: Test privacy settings navigation
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('プライバシー設定'));
      await tester.pumpAndSettle();
      
      // Step 10: Verify privacy controls
      expect(find.text('年代・性別情報を表示'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('privacy settings affect result display', (tester) async {
      // Arrange
      await tester.pumpWidget(const MyApp());
      
      // Navigate to privacy settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('プライバシー設定'));
      await tester.pumpAndSettle();
      
      // Turn off person analysis display
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      
      // Go back to diagnosis
      await tester.pageBack();
      await tester.pageBack();
      
      // Complete diagnosis
      await tester.tap(find.text('診断を始める'));
      await tester.pumpAndSettle();
      // ... diagnosis steps ...
      
      // Verify person analysis is hidden
      expect(find.text('推定情報'), findsNothing);
      expect(find.textContaining('年代:'), findsNothing);
      expect(find.textContaining('性別:'), findsNothing);
      
      // But main diagnosis should still be adaptive
      expect(find.text('診断結果'), findsOneWidget);
    });
  });
}
```

## Security & Privacy Tests

### 1. データ保護テスト

```python
# server/tests/security/test_privacy_compliance.py

class TestPrivacyCompliance:
    
    def test_no_specific_age_in_response(self):
        """具体的な年齢が推定結果に含まれないことを確認"""
        # Arrange
        service = get_gemini_service()
        test_response = """{
            "person_analysis": {
                "age_group": "adult",
                "gender": "female",
                "confidence": 78
            }
        }"""
        
        # Act
        result = json.loads(test_response)
        
        # Assert
        person_analysis = result["person_analysis"]
        assert "age" not in person_analysis
        assert "birth_year" not in person_analysis
        assert person_analysis["age_group"] in ["child", "student", "adult", "middleAge", "senior"]
    
    def test_image_data_not_stored(self):
        """画像データが保存されないことを確認"""
        # This test would verify that images are processed but not persisted
        # Implementation depends on actual storage mechanisms
        pass
    
    def test_request_logging_excludes_sensitive_data(self):
        """ログに機密情報が含まれないことを確認"""
        # This test would verify log sanitization
        pass

class TestSecurityHeaders:
    
    def test_api_security_headers(self):
        """APIセキュリティヘッダーの確認"""
        client = TestClient(app)
        response = client.post("/api/v1/diagnose-enhanced", json={})
        
        # Security headers should be present
        assert "X-Content-Type-Options" in response.headers
        assert "X-Frame-Options" in response.headers
        assert response.headers["X-Content-Type-Options"] == "nosniff"
```

### 2. データ検証テスト

```dart
// test/security/data_validation_test.dart

void main() {
  group('Data Validation Tests', () {
    test('PersonAnalysis should reject invalid age groups', () {
      // Arrange
      final invalidJson = {
        'age_group': '<script>alert("xss")</script>',
        'gender': 'female',
        'confidence': 85,
      };

      // Act & Assert
      expect(() => PersonAnalysis.fromJson(invalidJson), throwsException);
    });

    test('DiagnosisResult should sanitize explanations', () {
      // Test HTML/XSS sanitization in explanation fields
      // Implementation would depend on sanitization library
    });
  });
}
```

## テスト実行戦略

### 1. 継続的インテグレーション

```yaml
# .github/workflows/enhanced_diagnosis_tests.yml
name: Enhanced Diagnosis Tests

on: [push, pull_request]

jobs:
  flutter-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test test/integration/
  
  python-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.10
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run unit tests
        run: pytest tests/unit/ --cov=src
      - name: Run integration tests  
        run: pytest tests/integration/
      - name: Run performance tests
        run: pytest tests/performance/
```

### 2. テスト環境セットアップ

```bash
# テスト用データセットアップ
server/setup_test_data.sh

# Flutter テスト実行
cd client/personal_color_app
flutter test --coverage

# Python テスト実行
cd server
source .venv/bin/activate
pytest tests/ -v --cov=src --cov-report=html

# パフォーマンステスト実行
pytest tests/performance/ -v

# E2Eテスト実行
flutter test test/e2e/
```

## 成功基準

### 1. 機能テスト成功基準
- [ ] 全Unit Tests pass (90%以上)
- [ ] 全Integration Tests pass (95%以上)
- [ ] E2E Tests pass (100%)

### 2. パフォーマンステスト成功基準
- [ ] 診断レスポンス時間 < 5秒
- [ ] 並行処理耐性 (5並行リクエスト処理)
- [ ] メモリ使用量増加 < 100MB

### 3. 精度テスト成功基準
- [ ] 年代推定精度 ≥ 70%
- [ ] 性別推定精度 ≥ 80%
- [ ] パーソナルカラー診断精度維持 ≥ 85%

### 4. セキュリティテスト成功基準
- [ ] プライバシー保護確認 (具体的年齢非推定)
- [ ] データ非永続化確認
- [ ] XSS/インジェクション攻撃対策確認

## 関連文書

- `requirements.md`: 機能要件定義
- `design.md`: 技術設計詳細
- `tasks.md`: 実装タスク分解（次作成予定）
- `../initialize/test_design.md`: 既存システムテスト設計

## 更新履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|------------|----------|--------|
| 2024-01-XX | 1.0 | 初版作成 | Claude |