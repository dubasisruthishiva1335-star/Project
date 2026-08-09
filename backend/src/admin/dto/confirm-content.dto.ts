import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Transform } from 'class-transformer';

export class ConfirmContentDto {
  @IsString() title: string;
  @IsString() branch: string;

  @IsOptional()
  @Transform(({ value, obj }) => {
    const raw = value ?? obj.year ?? 1;
    return Number(raw);
  })
  @IsInt()
  @Min(1)
  @Max(8)
  semester?: number;

  @IsOptional()
  @Transform(({ value }) => (value !== undefined ? Number(value) : undefined))
  year?: number;

  @IsIn(['NOTES', 'QUESTION_BANK', 'SYLLABUS', 'LAB_MANUAL']) contentType: string;
  @IsString() s3Key: string;
  @IsOptional() @IsString() publicUrl?: string;
  @IsOptional() @IsString() subjectId?: string;
  @IsOptional() @IsString() subjectName?: string;
  @IsOptional() @IsString() subjectCode?: string;
}
